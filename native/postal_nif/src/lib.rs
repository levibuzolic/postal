use postal::{Context, ExpandAddressOptions, InitOptions, ParseAddressOptions};
use rustler::{Encoder, Env, Term};
use std::sync::OnceLock;

mod atoms {
    rustler::atoms! {
        ok,
        error,
    }
}

static CONTEXT: OnceLock<Result<Context, String>> = OnceLock::new();

fn get_context() -> Result<&'static Context, String> {
    let result = CONTEXT.get_or_init(|| {
        let mut ctx = Context::new();
        match ctx.init(InitOptions {
            expand_address: true,
            parse_address: true,
        }) {
            Ok(()) => Ok(ctx),
            Err(e) => Err(format!("libpostal init failed: {:?}", e)),
        }
    });

    match result {
        Ok(ctx) => Ok(ctx),
        Err(e) => Err(e.clone()),
    }
}

fn ok_tuple<'a, T: Encoder>(env: Env<'a>, value: T) -> Term<'a> {
    (atoms::ok(), value).encode(env)
}

fn error_tuple<'a>(env: Env<'a>, reason: &str) -> Term<'a> {
    (atoms::error(), reason).encode(env)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn setup(env: Env) -> Term {
    match get_context() {
        Ok(_) => atoms::ok().encode(env),
        Err(e) => error_tuple(env, &e),
    }
}

#[rustler::nif(schedule = "DirtyCpu")]
fn parse_address<'a>(env: Env<'a>, address: String) -> Term<'a> {
    let ctx = match get_context() {
        Ok(ctx) => ctx,
        Err(e) => return error_tuple(env, &e),
    };

    let mut opts = ParseAddressOptions::new();

    match ctx.parse_address(&address, &mut opts) {
        Ok(parsed) => {
            let components: Vec<(String, String)> = parsed
                .map(|c| (c.label.to_string(), c.value.to_string()))
                .collect();
            ok_tuple(env, components)
        }
        Err(e) => error_tuple(env, &format!("parse_address failed: {:?}", e)),
    }
}

#[rustler::nif(schedule = "DirtyCpu")]
fn expand_address<'a>(env: Env<'a>, address: String, languages: Vec<String>) -> Term<'a> {
    let ctx = match get_context() {
        Ok(ctx) => ctx,
        Err(e) => return error_tuple(env, &e),
    };

    let mut opts = ExpandAddressOptions::new();

    let lang_strs: Vec<&str> = languages.iter().map(|s| s.as_str()).collect();
    if !lang_strs.is_empty() {
        opts.set_languages(&lang_strs);
    }

    match ctx.expand_address(&address, &mut opts) {
        Ok(expansions) => {
            let result: Vec<String> = expansions.map(|s| s.to_string()).collect();
            ok_tuple(env, result)
        }
        Err(e) => error_tuple(env, &format!("expand_address failed: {:?}", e)),
    }
}

rustler::init!("Elixir.Postal.Native");
