From: Jesung Yang <y.j3ms.n@gmail.com>
Date: Thu, 25 Dec 2025 08:37:47 +0000
Subject: [PATCH v4 1/4] rust: macros: add derive macro for `Into`
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251225-try-from-into-macro-v4-1-4a563d597836@gmail.com>
References: <20251225-try-from-into-macro-v4-0-4a563d597836@gmail.com>
In-Reply-To: <20251225-try-from-into-macro-v4-0-4a563d597836@gmail.com>
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun.feng@gmail.com>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, Alexandre Courbot <acourbot@nvidia.com>
Cc: linux-kernel@vger.kernel.org, rust-for-linux@vger.kernel.org, 
 nouveau@lists.freedesktop.org, Jesung Yang <y.j3ms.n@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766651873; l=22554;
 i=y.j3ms.n@gmail.com; s=20251225; h=from:subject:message-id;
 bh=71sFAuNmqDmFx2Wy2tcO+Pz75k5Gz+cj97K17lcBWLY=;
 b=6+o7BxFUvUB4O0UQev7O+klPOgqok94E3YymJRBhjH98QA1VriXoYbhKdEbH51OeVXywDqYMt
 p25Un6Ic2qgDOnG8AiTky2MPOBGgYUPRleIT/tC+pWUkvlbzY9exTp3
X-Developer-Key: i=y.j3ms.n@gmail.com; a=ed25519;
 pk=2yVgO1I+y7kkFSF2Dc/Dckj4L2FgRnvmERHFt4bspbI=
X-Endpoint-Received: by B4 Relay for y.j3ms.n@gmail.com/20251225 with auth_id=586
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce a procedural macro `Into` to automatically implement the
`Into` trait for unit-only enums.

This reduces boilerplate in cases where enum variants need to be
interpreted as relevant numeric values. A concrete example can be
found in nova-core, where the `register!()` macro requires enum types
used within it to be convertible via `u32::from()` [1].

The macro not only supports primitive types such as `bool` or `i8`, but
also `Bounded`, a wrapper around integer types limiting the number of
bits usable for value representation. This accommodates the shift toward
more restrictive register field representations in nova-core where
values are constrained to specific bit ranges.

Note that the macro actually generates `From<E> for T` implementations,
where `E` is an enum identifier and `T` is an arbitrary integer type.
This automatically provides the corresponding `Into<T> for E`
implementations through the blanket implementation.

Link: https://lore.kernel.org/rust-for-linux/20250624132337.2242-1-dakr@kernel.org/ [1]
Signed-off-by: Jesung Yang <y.j3ms.n@gmail.com>
---
 rust/macros/convert.rs | 467 +++++++++++++++++++++++++++++++++++++++++++++++++
 rust/macros/lib.rs     | 157 +++++++++++++++++
 2 files changed, 624 insertions(+)

diff --git a/rust/macros/convert.rs b/rust/macros/convert.rs
new file mode 100644
index 0000000000000000000000000000000000000000..3e623cc894bff279482dd9daeaa7054937357ec6
--- /dev/null
+++ b/rust/macros/convert.rs
@@ -0,0 +1,467 @@
+// SPDX-License-Identifier: GPL-2.0
+
+use proc_macro2::{
+    Span,
+    TokenStream, //
+};
+
+use std::fmt;
+
+use syn::{
+    parse::{
+        Parse,
+        ParseStream, //
+    },
+    parse_quote,
+    parse_str,
+    punctuated::Punctuated,
+    spanned::Spanned,
+    Attribute,
+    Data,
+    DeriveInput,
+    Expr,
+    Fields,
+    Ident,
+    LitInt,
+    Token, //
+};
+
+pub(crate) fn derive_into(input: DeriveInput) -> syn::Result<TokenStream> {
+    derive(DeriveTarget::Into, input)
+}
+
+fn derive(target: DeriveTarget, input: DeriveInput) -> syn::Result<TokenStream> {
+    let mut errors: Option<syn::Error> = None;
+    let mut combine_error = |err| match errors.as_mut() {
+        Some(errors) => errors.combine(err),
+        None => errors = Some(err),
+    };
+
+    let (helper_tys, repr_ty) = parse_attrs(target, &input.attrs)?;
+    for ty in &helper_tys {
+        if let Err(err) = ty.validate() {
+            combine_error(err);
+        }
+    }
+
+    let data_enum = match input.data {
+        Data::Enum(data) => data,
+        Data::Struct(data) => {
+            let msg = format!(
+                "expected `enum`, found `struct`; \
+                 `#[derive({})]` can only be applied to a unit-only enum",
+                target.get_trait_name()
+            );
+            return Err(syn::Error::new(data.struct_token.span(), msg));
+        }
+        Data::Union(data) => {
+            let msg = format!(
+                "expected `enum`, found `union`; \
+                 `#[derive({})]` can only be applied to a unit-only enum",
+                target.get_trait_name()
+            );
+            return Err(syn::Error::new(data.union_token.span(), msg));
+        }
+    };
+
+    for variant in &data_enum.variants {
+        match &variant.fields {
+            Fields::Named(fields) => {
+                let msg = format!(
+                    "expected unit-like variant, found struct-like variant; \
+                    `#[derive({})]` can only be applied to a unit-only enum",
+                    target.get_trait_name()
+                );
+                combine_error(syn::Error::new_spanned(fields, msg));
+            }
+            Fields::Unnamed(fields) => {
+                let msg = format!(
+                    "expected unit-like variant, found tuple-like variant; \
+                    `#[derive({})]` can only be applied to a unit-only enum",
+                    target.get_trait_name()
+                );
+                combine_error(syn::Error::new_spanned(fields, msg));
+            }
+            _ => (),
+        }
+    }
+
+    if let Some(errors) = errors {
+        return Err(errors);
+    }
+
+    let variants: Vec<_> = data_enum
+        .variants
+        .into_iter()
+        .map(|variant| variant.ident)
+        .collect();
+
+    Ok(derive_for_enum(
+        target,
+        &input.ident,
+        &variants,
+        &helper_tys,
+        &repr_ty,
+    ))
+}
+
+#[derive(Clone, Copy, Debug)]
+enum DeriveTarget {
+    Into,
+}
+
+impl DeriveTarget {
+    fn get_trait_name(&self) -> &'static str {
+        match self {
+            Self::Into => "Into",
+        }
+    }
+
+    fn get_helper_name(&self) -> &'static str {
+        match self {
+            Self::Into => "into",
+        }
+    }
+}
+
+fn parse_attrs(target: DeriveTarget, attrs: &[Attribute]) -> syn::Result<(Vec<ValidTy>, Ident)> {
+    let helper = target.get_helper_name();
+
+    let mut repr_ty = None;
+    let mut helper_tys = Vec::new();
+    for attr in attrs {
+        if attr.path().is_ident("repr") {
+            attr.parse_nested_meta(|meta| {
+                let ident = meta.path.get_ident();
+                if ident.is_some_and(is_valid_primitive) {
+                    repr_ty = ident.cloned();
+                }
+                // Delegate `repr` attribute validation to rustc.
+                Ok(())
+            })?;
+        } else if attr.path().is_ident(helper) && helper_tys.is_empty() {
+            let args = attr.parse_args_with(Punctuated::<ValidTy, Token![,]>::parse_terminated)?;
+            helper_tys.extend(args);
+        }
+    }
+
+    // Note on field-less `repr(C)` enums (quote from [1]):
+    //
+    //   In C, enums with discriminants that do not all fit into an `int` or all fit into an
+    //   `unsigned int` are a portability hazard: such enums are only permitted since C23, and not
+    //   supported e.g. by MSVC.
+    //
+    //   Furthermore, Rust interprets the discriminant values of `repr(C)` enums as expressions of
+    //   type `isize`. This makes it impossible to implement the C23 behavior of enums where the
+    //   enum discriminants have no predefined type and instead the enum uses a type large enough
+    //   to hold all discriminants.
+    //
+    //   Therefore, `repr(C)` enums in Rust require that either all discriminants to fit into a C
+    //   `int` or they all fit into an `unsigned int`.
+    //
+    // As such, `isize` is a reasonable representation for `repr(C)` enums, as it covers the range
+    //  of both `int` and `unsigned int`.
+    //
+    // For more information, see:
+    // - https://github.com/rust-lang/rust/issues/124403
+    // - https://github.com/rust-lang/rust/pull/147017
+    // - https://github.com/rust-lang/rust/blob/2ca7bcd03b87b52f7055a59b817443b0ac4a530d/compiler/rustc_lint_defs/src/builtin.rs#L5251-L5263 [1]
+
+    // Extract the representation passed by `#[repr(...)]` if present. If nothing is
+    // specified, the default is `Rust` representation, which uses `isize` for its
+    // discriminant type.
+    // See: https://doc.rust-lang.org/reference/items/enumerations.html#r-items.enum.discriminant.repr-rust
+    let repr_ty = repr_ty.unwrap_or_else(|| Ident::new("isize", Span::call_site()));
+    Ok((helper_tys, repr_ty))
+}
+
+fn derive_for_enum(
+    target: DeriveTarget,
+    enum_ident: &Ident,
+    variants: &[Ident],
+    helper_tys: &[ValidTy],
+    repr_ty: &Ident,
+) -> TokenStream {
+    let impl_fn = match target {
+        DeriveTarget::Into => impl_into,
+    };
+
+    let qualified_repr_ty: syn::Path = parse_quote! { ::core::primitive::#repr_ty };
+
+    return if helper_tys.is_empty() {
+        let ty = ValidTy::Primitive(repr_ty.clone());
+        let impls =
+            std::iter::once(ty).map(|ty| impl_fn(enum_ident, variants, &qualified_repr_ty, &ty));
+        ::quote::quote! { #(#impls)* }
+    } else {
+        let impls = helper_tys
+            .iter()
+            .map(|ty| impl_fn(enum_ident, variants, &qualified_repr_ty, ty));
+        ::quote::quote! { #(#impls)* }
+    };
+
+    fn impl_into(
+        enum_ident: &Ident,
+        variants: &[Ident],
+        repr_ty: &syn::Path,
+        input_ty: &ValidTy,
+    ) -> TokenStream {
+        let param = Ident::new("value", Span::call_site());
+
+        let overflow_assertion = emit_overflow_assert(enum_ident, variants, repr_ty, input_ty);
+        let cast = match input_ty {
+            ValidTy::Bounded(inner) => {
+                let base_ty = inner.emit_qualified_base_ty();
+                let expr = parse_quote! { #param as #base_ty };
+                // Since the discriminant of `#param`, an enum variant, is determined
+                // at compile-time, we can rely on `Bounded::from_expr()`. It requires
+                // the provided expression to be verifiable at compile-time to avoid
+                // triggering a build error.
+                inner.emit_from_expr(&expr)
+            }
+            ValidTy::Primitive(ident) if ident == "bool" => {
+                ::quote::quote! { (#param as #repr_ty) == 1 }
+            }
+            qualified @ ValidTy::Primitive(_) => ::quote::quote! { #param as #qualified },
+        };
+
+        ::quote::quote! {
+            #[automatically_derived]
+            impl ::core::convert::From<#enum_ident> for #input_ty {
+                fn from(#param: #enum_ident) -> #input_ty {
+                    #overflow_assertion
+
+                    #cast
+                }
+            }
+        }
+    }
+
+    fn emit_overflow_assert(
+        enum_ident: &Ident,
+        variants: &[Ident],
+        repr_ty: &syn::Path,
+        input_ty: &ValidTy,
+    ) -> TokenStream {
+        let qualified_i128: syn::Path = parse_quote! { ::core::primitive::i128 };
+        let qualified_u128: syn::Path = parse_quote! { ::core::primitive::u128 };
+
+        let input_min = input_ty.emit_min();
+        let input_max = input_ty.emit_max();
+
+        let variant_fits = variants.iter().map(|variant| {
+            let msg = format!(
+                "enum discriminant overflow: \
+                `{enum_ident}::{variant}` does not fit in `{input_ty}`",
+            );
+            ::quote::quote! {
+                ::core::assert!(fits(#enum_ident::#variant as #repr_ty), #msg);
+            }
+        });
+
+        ::quote::quote! {
+            const _: () = {
+                const fn fits(d: #repr_ty) -> ::core::primitive::bool {
+                    // For every integer type, its minimum value always fits in `i128`.
+                    let dst_min = #input_min;
+                    // For every integer type, its maximum value always fits in `u128`.
+                    let dst_max = #input_max;
+
+                    #[allow(unused_comparisons)]
+                    let is_src_signed = #repr_ty::MIN < 0;
+                    #[allow(unused_comparisons)]
+                    let is_dst_signed = dst_min < 0;
+
+                    if is_src_signed && is_dst_signed {
+                        // Casting from a signed value to `i128` does not overflow since
+                        // `i128` is the largest signed primitive integer type.
+                        (d as #qualified_i128) >= (dst_min as #qualified_i128)
+                            && (d as #qualified_i128) <= (dst_max as #qualified_i128)
+                    } else if is_src_signed && !is_dst_signed {
+                        // Casting from a signed value greater than 0 to `u128` does not
+                        // overflow since `u128::MAX` is greater than `i128::MAX`.
+                        d >= 0 && (d as #qualified_u128) <= (dst_max as #qualified_u128)
+                    } else {
+                        // Casting from an unsigned value to `u128` does not overflow since
+                        // `u128` is the largest unsigned primitive integer type.
+                        (d as #qualified_u128) <= (dst_max as #qualified_u128)
+                    }
+                }
+
+                #(#variant_fits)*
+            };
+        }
+    }
+}
+
+enum ValidTy {
+    Bounded(Bounded),
+    Primitive(Ident),
+}
+
+impl ValidTy {
+    fn validate(&self) -> syn::Result<()> {
+        match self {
+            Self::Bounded(inner) => inner.validate(),
+            Self::Primitive(ident) => validate_primitive(ident),
+        }
+    }
+
+    fn emit_min(&self) -> TokenStream {
+        match self {
+            Self::Bounded(inner) => inner.emit_min(),
+            Self::Primitive(ident) if ident == "bool" => {
+                ::quote::quote! { 0 }
+            }
+            qualified @ Self::Primitive(_) => ::quote::quote! { #qualified::MIN },
+        }
+    }
+
+    fn emit_max(&self) -> TokenStream {
+        match self {
+            Self::Bounded(inner) => inner.emit_max(),
+            Self::Primitive(ident) if ident == "bool" => {
+                ::quote::quote! { 1 }
+            }
+            qualified @ Self::Primitive(_) => ::quote::quote! { #qualified::MAX },
+        }
+    }
+}
+
+impl Parse for ValidTy {
+    fn parse(input: ParseStream<'_>) -> syn::Result<Self> {
+        if input.peek(Ident) && input.peek2(Token![<]) {
+            return Ok(ValidTy::Bounded(input.parse()?));
+        }
+        Ok(ValidTy::Primitive(input.parse()?))
+    }
+}
+
+impl ::quote::ToTokens for ValidTy {
+    fn to_tokens(&self, tokens: &mut TokenStream) {
+        match self {
+            Self::Bounded(inner) => inner.to_tokens(tokens),
+            Self::Primitive(ident) => {
+                let qualified_name: syn::Path = parse_quote! { ::core::primitive::#ident };
+                qualified_name.to_tokens(tokens)
+            }
+        }
+    }
+}
+
+impl fmt::Display for ValidTy {
+    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
+        match self {
+            Self::Bounded(inner) => inner.fmt(f),
+            Self::Primitive(ident) => ident.fmt(f),
+        }
+    }
+}
+
+struct Bounded {
+    name: Ident,
+    open_angle: Token![<],
+    base_ty: Ident,
+    comma: Token![,],
+    bits: LitInt,
+    close_angle: Token![>],
+}
+
+impl Bounded {
+    const NAME: &'static str = "Bounded";
+    const QUALIFIED_NAME: &'static str = "::kernel::num::Bounded";
+
+    fn validate(&self) -> syn::Result<()> {
+        let name = &self.name;
+        if name != Self::NAME {
+            let msg = format!("expected `{}`, found {}", Self::NAME, name);
+            return Err(syn::Error::new(name.span(), msg));
+        }
+        validate_primitive(&self.base_ty)?;
+        Ok(())
+    }
+
+    fn emit_from_expr(&self, expr: &Expr) -> TokenStream {
+        let Self { base_ty, bits, .. } = self;
+        let qualified_name: syn::Path = parse_str(Self::QUALIFIED_NAME).expect("valid path");
+        ::quote::quote! {
+            #qualified_name::<#base_ty, #bits>::from_expr(#expr)
+        }
+    }
+
+    fn emit_qualified_base_ty(&self) -> TokenStream {
+        let base_ty = &self.base_ty;
+        ::quote::quote! { ::core::primitive::#base_ty }
+    }
+
+    fn emit_min(&self) -> TokenStream {
+        let bits = &self.bits;
+        let base_ty = self.emit_qualified_base_ty();
+        ::quote::quote! { #base_ty::MIN >> (#base_ty::BITS - #bits) }
+    }
+
+    fn emit_max(&self) -> TokenStream {
+        let bits = &self.bits;
+        let base_ty = self.emit_qualified_base_ty();
+        ::quote::quote! { #base_ty::MAX >> (#base_ty::BITS - #bits) }
+    }
+}
+
+impl Parse for Bounded {
+    fn parse(input: ParseStream<'_>) -> syn::Result<Self> {
+        Ok(Self {
+            name: input.parse()?,
+            open_angle: input.parse()?,
+            base_ty: input.parse()?,
+            comma: input.parse()?,
+            bits: input.parse()?,
+            close_angle: input.parse()?,
+        })
+    }
+}
+
+impl ::quote::ToTokens for Bounded {
+    fn to_tokens(&self, tokens: &mut TokenStream) {
+        let qualified_name: syn::Path = parse_str(Self::QUALIFIED_NAME).expect("valid path");
+        qualified_name.to_tokens(tokens);
+        self.open_angle.to_tokens(tokens);
+        self.base_ty.to_tokens(tokens);
+        self.comma.to_tokens(tokens);
+        self.bits.to_tokens(tokens);
+        self.close_angle.to_tokens(tokens);
+    }
+}
+
+impl fmt::Display for Bounded {
+    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
+        write!(f, "{}<{}, {}>", Self::NAME, self.base_ty, self.bits)
+    }
+}
+
+fn validate_primitive(ident: &Ident) -> syn::Result<()> {
+    if is_valid_primitive(ident) {
+        return Ok(());
+    }
+    let msg =
+        format!("expected `bool` or primitive integer type (e.g., `u8`, `i8`), found {ident}");
+    Err(syn::Error::new(ident.span(), msg))
+}
+
+fn is_valid_primitive(ident: &Ident) -> bool {
+    matches!(
+        ident.to_string().as_str(),
+        "bool"
+            | "u8"
+            | "u16"
+            | "u32"
+            | "u64"
+            | "u128"
+            | "usize"
+            | "i8"
+            | "i16"
+            | "i32"
+            | "i64"
+            | "i128"
+            | "isize"
+    )
+}
diff --git a/rust/macros/lib.rs b/rust/macros/lib.rs
index b38002151871a33f6b4efea70be2deb6ddad38e2..02528d7212b75d28788f0c33479edb272fa12e27 100644
--- a/rust/macros/lib.rs
+++ b/rust/macros/lib.rs
@@ -14,6 +14,7 @@
 #[macro_use]
 mod quote;
 mod concat_idents;
+mod convert;
 mod export;
 mod fmt;
 mod helpers;
@@ -23,6 +24,10 @@
 mod vtable;
 
 use proc_macro::TokenStream;
+use syn::{
+    parse_macro_input,
+    DeriveInput, //
+};
 
 /// Declares a kernel module.
 ///
@@ -475,3 +480,155 @@ pub fn paste(input: TokenStream) -> TokenStream {
 pub fn kunit_tests(attr: TokenStream, ts: TokenStream) -> TokenStream {
     kunit::kunit_tests(attr, ts)
 }
+
+/// A derive macro for providing an implementation of the [`Into`] trait.
+///
+/// This macro automatically derives the [`Into`] trait for a given enum by generating
+/// the relevant [`From`] implementation. Currently, it only supports [unit-only enum]s.
+///
+/// [unit-only enum]: https://doc.rust-lang.org/reference/items/enumerations.html#r-items.enum.unit-only
+///
+/// # Notes
+///
+/// - Unlike its name suggests, the macro actually generates [`From`] implementations
+///   which automatically provide corresponding [`Into`] implementations.
+///
+/// - The macro uses the `into` custom attribute or `repr` attribute to generate [`From`]
+///   implementations. `into` always takes precedence over `repr`.
+///
+/// - The macro generates a compile-time assertion for every variant to ensure its
+///   discriminant value fits within the type being converted into.
+///
+/// # Supported types in `#[into(...)]`
+///
+/// - [`bool`]
+/// - Primitive integer types (e.g., [`i8`], [`u8`])
+/// - [`Bounded`]
+///
+/// [`Bounded`]: ../kernel/num/bounded/struct.Bounded.html
+///
+/// # Examples
+///
+/// ## Without Attributes
+///
+/// Since [the default `Rust` representation uses `isize` for the discriminant type][repr-rust],
+/// the macro implements `From<Foo>` for `isize`:
+///
+/// [repr-rust]: https://doc.rust-lang.org/reference/items/enumerations.html#r-items.enum.discriminant.repr-rust
+///
+/// ```
+/// use kernel::macros::Into;
+///
+/// #[derive(Debug, Default, Into)]
+/// enum Foo {
+///     #[default]
+///     A,
+///     B = 0x7,
+/// }
+///
+/// assert_eq!(0_isize, Foo::A.into());
+/// assert_eq!(0x7_isize, Foo::B.into());
+/// ```
+///
+/// ## With `#[repr(T)]`
+///
+/// The macro implements `From<Foo>` for `T`:
+///
+/// ```
+/// use kernel::macros::Into;
+///
+/// #[derive(Debug, Default, Into)]
+/// #[repr(u8)]
+/// enum Foo {
+///     #[default]
+///     A,
+///     B = 0x7,
+/// }
+///
+/// assert_eq!(0_u8, Foo::A.into());
+/// assert_eq!(0x7_u8, Foo::B.into());
+/// ```
+///
+/// ## With `#[into(...)]`
+///
+/// The macro implements `From<Foo>` for each `T` specified in `#[into(...)]`,
+/// which always overrides `#[repr(...)]`:
+///
+/// ```
+/// use kernel::{
+///     macros::Into,
+///     num::Bounded, //
+/// };
+///
+/// #[derive(Debug, Default, Into)]
+/// #[into(bool, i16, Bounded<u8, 4>)]
+/// #[repr(u8)]
+/// enum Foo {
+///     #[default]
+///     A,
+///     B,
+/// }
+///
+/// assert_eq!(false, Foo::A.into());
+/// assert_eq!(true, Foo::B.into());
+///
+/// assert_eq!(0_i16, Foo::A.into());
+/// assert_eq!(1_i16, Foo::B.into());
+///
+/// let foo_a: Bounded<u8, 4> = Foo::A.into();
+/// let foo_b: Bounded<u8, 4> = Foo::B.into();
+/// assert_eq!(Bounded::<u8, 4>::new::<0>(), foo_a);
+/// assert_eq!(Bounded::<u8, 4>::new::<1>(), foo_b);
+/// ```
+///
+/// ## Compile-time Overflow Assertion
+///
+/// The following examples do not compile:
+///
+/// ```compile_fail
+/// # use kernel::macros::Into;
+/// #[derive(Into)]
+/// #[into(u8)]
+/// enum Foo {
+///     // `256` is larger than `u8::MAX`.
+///     A = 256,
+/// }
+/// ```
+///
+/// ```compile_fail
+/// # use kernel::macros::Into;
+/// #[derive(Into)]
+/// #[into(u8)]
+/// enum Foo {
+///     // `-1` cannot be represented with `u8`.
+///     A = -1,
+/// }
+/// ```
+///
+/// ## Unsupported Cases
+///
+/// The following examples do not compile:
+///
+/// ```compile_fail
+/// # use kernel::macros::Into;
+/// // Tuple-like enums or struct-like enums are not allowed.
+/// #[derive(Into)]
+/// enum Foo {
+///     A(u8),
+///     B { inner: u8 },
+/// }
+/// ```
+///
+/// ```compile_fail
+/// # use kernel::macros::Into;
+/// // Structs are not allowed.
+/// #[derive(Into)]
+/// struct Foo(u8);
+/// ```
+#[proc_macro_derive(Into, attributes(into))]
+pub fn derive_into(input: TokenStream) -> TokenStream {
+    let input = parse_macro_input!(input as DeriveInput);
+    convert::derive_into(input)
+        .unwrap_or_else(syn::Error::into_compile_error)
+        .into()
+}

-- 
2.47.3

