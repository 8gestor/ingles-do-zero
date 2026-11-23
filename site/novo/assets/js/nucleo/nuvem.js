/*
 * nuvem.js — conta e sincronização do progresso (Supabase pela API REST com `fetch`, sem biblioteca), docs/07 seção 4.8.
 *
 * Port do bloco de nuvem de `ingles-sync.js` do app de hoje. Compartilha as MESMAS chaves de sessão (`dd-sync-sess`, `dd-sync-last`,
 * `dd-sync-device`): quem entra num app já está dentro no outro (mesmo endereço). Local primeiro: tudo funciona e salva sem conta; a nuvem só
 * COPIA e MESCLA o progresso (nunca o texto dos livros). Configuração em `assets/js/sync-config.js` (`window.DD_SYNC = { url, key }`, chave
 * pública "anon"; vazio = recurso desligado e o app segue normal). NUNCA colocar a chave `service_role` no site.
 *
 * Login por CÓDIGO digitado (nunca por link): funciona em e-reader, TV e qualquer aparelho. Gravação condicionada a `updated_at`:
 * se outro aparelho gravou no meio, relê, mescla e tenta de novo (até 4 vezes).
 */
App.define('nuvem', ['eventos', 'armazem', 'mescla', 'dados', 'registro'], function (deps) {
    'use strict';
    const ev = deps.eventos, ls = deps.armazem.ls, M = deps.mescla, dados = deps.dados, reg = deps.registro;
    const conf = () => window.DD_SYNC || {};                      // lido na hora de usar (a configuração pode chegar depois)
    const ligada = () => !!(conf().url && conf().key);
    const SK = 'dd-sync-sess', LK = 'dd-sync-last';
    const jget = (k, def) => { const v = ls.get(k, def); return v == null ? def : v; };
    let sess = jget(SK, null), ocupado = false, ultima = jget(LK, { at: 0, hash: '' });
    let estado = sess ? 'in' : 'out', msg = '', emailPendente = '', ultimoErro = '', abertos = () => [];

    function avisar() { ev.emit('nuvem-estado', { estado, msg }); }
    const base = () => String(conf().url || '').replace(/\/+$/, '');
    async function http(path, opt, autenticado) {
        const o = opt || {}, headers = Object.assign({ apikey: conf().key, 'Content-Type': 'application/json' }, o.headers || {});
        if (autenticado) { await garantirToken(); headers.Authorization = 'Bearer ' + (sess ? sess.access_token : conf().key); }
        const r = await fetch(base() + path, { method: o.method || 'GET', headers, body: o.body ? JSON.stringify(o.body) : undefined });
        let j = null; try { j = await r.json(); } catch (e) { /* sem corpo */ }
        return { ok: r.ok, status: r.status, json: j };
    }
    function guardarSessao(j) {
        if (!j || !j.access_token) return false;
        sess = { access_token: j.access_token, refresh_token: j.refresh_token || (sess && sess.refresh_token), expires_at: Date.now() + (Number(j.expires_in) || 3600) * 1000, uid: (j.user && j.user.id) || (sess && sess.uid), email: (j.user && j.user.email) || (sess && sess.email) || emailPendente };
        ls.set(SK, sess); return true;
    }
    async function garantirToken() {
        if (!sess || sess.expires_at - Date.now() > 60000) return;
        const r = await http('/auth/v1/token?grant_type=refresh_token', { method: 'POST', body: { refresh_token: sess.refresh_token } }, false);
        if (r.ok && guardarSessao(r.json)) return;
        if (r.status === 400 || r.status === 401) { sess = null; ls.remove(SK); estado = 'out'; throw new Error('session'); }
        throw new Error('rede');
    }
    // motivo técnico da falha (aparece na tela para facilitar achar o problema)
    const porque = (r) => r.status + ((r.json && (r.json.msg || r.json.message || r.json.error_description || r.json.error_code || r.json.error)) ? ': ' + (r.json.msg || r.json.message || r.json.error_description || r.json.error_code || r.json.error) : '');

    async function enviarCodigo(email) {
        if (!ligada()) { emailPendente = ''; ultimoErro = 'não configurada'; msg = 'fail'; avisar(); return false; }                  // sincronização desligada: nem chama a rede
        if (!/.+@.+\..+/.test(String(email || ''))) { emailPendente = ''; ultimoErro = ''; msg = 'fail'; avisar(); return false; }      // e-mail inválido: nem chama a rede
        emailPendente = email; ultimoErro = ''; let ok = false;
        try { const r = await http('/auth/v1/otp', { method: 'POST', body: { email, create_user: true } }, false); ok = r.ok; if (!ok) ultimoErro = porque(r); }
        catch (e) { ok = false; ultimoErro = 'rede: ' + String((e && e.message) || e); }
        msg = ok ? 'sent' : 'fail'; if (!ok) emailPendente = ''; avisar(); return ok;
    }
    async function verificar(email, codigo) {
        let r = await http('/auth/v1/verify', { method: 'POST', body: { type: 'email', email, token: codigo } }, false);
        if (!r.ok) r = await http('/auth/v1/verify', { method: 'POST', body: { type: 'magiclink', email, token: codigo } }, false);
        if (!r.ok) r = await http('/auth/v1/verify', { method: 'POST', body: { type: 'signup', email, token: codigo } }, false);      // conta nova: o e-mail de confirmação também traz o código
        return r.ok && guardarSessao(r.json);
    }
    async function entrar(codigo) {
        let ok = false; try { ok = await verificar(emailPendente, String(codigo || '').trim()); } catch (e) { ok = false; }
        if (ok) { estado = 'in'; msg = ''; emailPendente = ''; avisar(); sincronizar('login'); } else { msg = 'bad'; avisar(); }
        return ok;
    }
    function sair() { sess = null; ls.remove(SK); estado = 'out'; msg = ''; emailPendente = ''; avisar(); }

    async function lerLinha() {
        const r = await http('/rest/v1/progress?select=data,updated_at&limit=1', {}, true);
        if (!r.ok) throw new Error('get ' + r.status);
        return Array.isArray(r.json) && r.json[0] ? r.json[0] : null;
    }
    async function gravarLinha(data, anterior) {
        const agora = new Date().toISOString();
        if (!anterior) {
            const r = await http('/rest/v1/progress', { method: 'POST', headers: { Prefer: 'return=minimal' }, body: { user_id: sess.uid, data, device: dados.aparelho(), updated_at: agora } }, true);
            if (r.status === 409) return false;                                       // outro aparelho criou antes: relê e mescla
            if (!r.ok) throw new Error('post ' + r.status);
            return true;
        }
        const r = await http('/rest/v1/progress?user_id=eq.' + encodeURIComponent(sess.uid) + '&updated_at=eq.' + encodeURIComponent(anterior), { method: 'PATCH', headers: { Prefer: 'return=representation' }, body: { data, device: dados.aparelho(), updated_at: agora } }, true);
        if (!r.ok) throw new Error('patch ' + r.status);
        return Array.isArray(r.json) && r.json.length > 0;                            // vazio = outro aparelho gravou no meio: relê e mescla
    }
    async function sincronizar(motivo) {
        if (!ligada() || !sess || ocupado) return false;
        ocupado = true; estado = 'sync'; avisar();
        const concluiu = (h) => { ultima = { at: Date.now(), hash: h }; ls.set(LK, ultima); estado = 'in'; msg = ''; ocupado = false; avisar(); return true; };
        try {
            reg.salvar(); ev.emit('sincronia-comecando', { motivo: motivo || '' });
            const device = dados.aparelho();
            for (let tentativa = 0; tentativa < 4; tentativa++) {
                const linha = await lerLinha(), local = await dados.snapshot();
                const mesclado = linha ? M.merge(local, linha.data, { device }) : local;
                await dados.apply(mesclado, { abertos: abertos(), origem: 'nuvem' });
                const final = await dados.snapshot(), h = M.hash(M.stable(final));
                if (linha && M.hash(M.stable(M.merge(final, linha.data, { device }))) === M.hash(M.stable(linha.data)) && h === M.hash(M.stable(linha.data))) return concluiu(h);
                if (await gravarLinha(M.merge(final, linha ? linha.data : null, { device }), linha ? linha.updated_at : null)) return concluiu(h);
            }
            throw new Error('conflito');
        } catch (e) { estado = sess ? 'in' : 'out'; msg = String(e && e.message) === 'session' ? 'session' : 'offline'; }
        ocupado = false; avisar(); return false;
    }
    let timer = null;
    function agendar(ms) { if (!ligada() || !sess) return; clearTimeout(timer); timer = setTimeout(() => sincronizar('evento'), ms); }

    /* quando sincronizar */
    ev.on('livro-fechado', () => agendar(2500)); ev.on('palavra-salva', () => agendar(15000)); ev.on('revisao-feita', () => agendar(15000));
    ev.on('escrita-salva', () => agendar(5000)); ev.on('livro-importado', () => agendar(5000));
    document.addEventListener('visibilitychange', () => { if (document.visibilityState === 'hidden') agendar(200); else agendar(500); });
    setInterval(() => { if (document.visibilityState === 'visible' && sess && !ocupado) dados.snapshot().then((s) => { if (M.hash(M.stable(s)) !== ultima.hash) sincronizar('periodico'); }).catch(() => {}); }, 60000);
    if (ligada() && sess) agendar(1500);

    return {
        ligada, enviarCodigo, entrar, sair, sincronizar, agendar,
        definirAbertos(fn) { abertos = typeof fn === 'function' ? fn : () => []; },       // o leitor informa quais livros estão abertos
        estado: () => ({ estado, msg, configurada: ligada(), logado: !!sess, email: (sess && sess.email) || '', pendente: emailPendente, ultima: ultima.at || 0, erro: ultimoErro })
    };
});
