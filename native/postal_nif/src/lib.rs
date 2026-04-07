use postal::{Context, ExpandAddressOptions, InitOptions, ParseAddressOptions};
use rustler::{Atom, Error, NifResult};
use std::sync::OnceLock;

mod atoms {
    rustler::atoms! {
        ok,
        error,
    }
}

static CONTEXT: OnceLock<Result<Context, String>> = OnceLock::new();

fn get_context() -> NifResult<&'static Context> {
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
        Err(e) => Err(Error::Term(Box::new(e.clone()))),
    }
}

#[rustler::nif(schedule = "DirtyCpu")]
fn setup() -> NifResult<Atom> {
    get_context()?;
    Ok(atoms::ok())
}

#[rustler::nif(schedule = "DirtyCpu")]
fn parse_address(address: String) -> NifResult<(Atom, Vec<(String, String)>)> {
    let ctx = get_context()?;

    let mut opts = ParseAddressOptions::new();

    let parsed = ctx
        .parse_address(&address, &mut opts)
        .map_err(|e| Error::Term(Box::new(format!("parse_address failed: {:?}", e))))?;

    let components: Vec<(String, String)> = parsed
        .map(|c| (c.label.to_string(), c.value.to_string()))
        .collect();

    Ok((atoms::ok(), components))
}

#[rustler::nif(schedule = "DirtyCpu")]
fn expand_address(address: String, languages: Vec<String>) -> NifResult<(Atom, Vec<String>)> {
    let ctx = get_context()?;

    let mut opts = ExpandAddressOptions::new();

    let lang_strs: Vec<&str> = languages.iter().map(|s| s.as_str()).collect();
    if !lang_strs.is_empty() {
        opts.set_languages(&lang_strs);
    }

    let expansions = ctx
        .expand_address(&address, &mut opts)
        .map_err(|e| Error::Term(Box::new(format!("expand_address failed: {:?}", e))))?;

    let result: Vec<String> = expansions.map(|s| s.to_string()).collect();

    Ok((atoms::ok(), result))
}

rustler::init!("Elixir.Postal.Native");
