From: Jesung Yang <y.j3ms.n@gmail.com>
Date: Thu, 29 Jan 2026 23:32:46 +0900
Subject: [PATCH v5 2/4] rust: macros: add derive macro for `TryFrom`
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260129-try-from-into-macro-v5-2-dd011008118c@gmail.com>
References: <20260129-try-from-into-macro-v5-0-dd011008118c@gmail.com>
In-Reply-To: <20260129-try-from-into-macro-v5-0-dd011008118c@gmail.com>
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun.feng@gmail.com>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, Alexandre Courbot <acourbot@nvidia.com>
Cc: linux-kernel@vger.kernel.org, rust-for-linux@vger.kernel.org, 
 nouveau@lists.freedesktop.org, Jesung Yang <y.j3ms.n@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=10808; i=y.j3ms.n@gmail.com;
 h=from:subject:message-id; bh=o0ZOJ2u6fulpd6euQbCwZeiZqbQpSA+Y1ClbiBC4Hqs=;
 b=owJ4nAFtApL9kA0DAAoBhnBYoOPQ2LoByyZiAGl7b47aA5WH7vO27Eax/xs4+3OV8/xJrrBLu
 hHqXotpVMg9EIkCMwQAAQoAHRYhBNJuBqTTLsbEgOaQ0IZwWKDj0Ni6BQJpe2+OAAoJEIZwWKDj
 0Ni6a3UP/3v9YccMDx0NI+IfLLnZQdKyC6kjqKkTFuVFtmyU6+abCyBRfivWFQYEKwv/C2PIOCu
 5GWkMvGyD+iHz4VyhYgOd9JBoNL+KjQXI7uF5zQpzWFCA9zvt97gw76K94El2Kwl1SHAtoBsF4e
 oRHmUAMvwHwoc+Bvq9GIwiAuEcyafDMX8ktwYxUb9U61fqBPKZKpH7jPf2Rc4/bd3OMO/Yw55Pa
 ivdiSFO7wmXSI3r0OJdja66PWAiga0URV97XZEVTlJZkRgNScrbCxF5nARxrI1DAIddchIZUHb0
 +UcaMrnW1s7GoBP0N4kHVPl95jVAgFZiBMTkrk/q0erR3suHOpYYmPkOcAN0wu5xidpfi5io66q
 TvKnfY/WmGvZGEwYA1zy6/X9XPQEd4U+F8GVsybDP7KebzrbbONMVyNeMw6m7fDTiVMKYrxBDXh
 Cd/k58ErBtHwAPJaVI4o8P12+diboiAPNUmlPVqEKugfktgftNS/krbpA0Yx1G6NjZD1L/EHD3J
 k/3ieugATWzJKLNajrchxDi44HIgYfS4TXc0wOUINjBE0kfYoJZSjuO7bB8QSaNxTg1+IHOQv51
 YYmCwkQiaPHH4eCGX7Mwe1bM3SIrZFDJUh11uWRHLYo1MANAzrqky2dCCAc6HWvb5hxg2pIW4hs
 DSgBGXklSMMUG6xxt8fspUw==
X-Developer-Key: i=y.j3ms.n@gmail.com; a=openpgp;
 fpr=D26E06A4D32EC6C480E690D0867058A0E3D0D8BA
X-Endpoint-Received: by B4 Relay for y.j3ms.n@gmail.com/default with auth_id=602
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce a procedural macro `TryFrom` to automatically implement the
`TryFrom` trait for unit-only enums.

This reduces boilerplate in cases where numeric values need to be
interpreted as relevant enum variants. This situation often arises when
working with low-level data sources. A typical example is the `Chipset`
enum in nova-core, where the value read from a GPU register should be
mapped to a corresponding variant.

The macro not only supports primitive types such as `bool` or `i8`, but
also `Bounded`, a wrapper around integer types limiting the number of
bits usable for value representation. This accommodates the shift toward
more restrictive register field representations in nova-core where
values are constrained to specific bit ranges.

Signed-off-by: Jesung Yang <y.j3ms.n@gmail.com>
---
 rust/macros/convert.rs |  64 ++++++++++++++++++
 rust/macros/lib.rs     | 176 +++++++++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 240 insertions(+)

diff --git a/rust/macros/convert.rs b/rust/macros/convert.rs
index 096e3c9fdc1b..a7a43b1a2caf 100644
--- a/rust/macros/convert.rs
+++ b/rust/macros/convert.rs
@@ -34,6 +34,10 @@ pub(crate) fn derive_into(input: DeriveInput) -> syn::Result<TokenStream> {
     derive(DeriveTarget::Into, input)
 }
 
+pub(crate) fn derive_try_from(input: DeriveInput) -> syn::Result<TokenStream> {
+    derive(DeriveTarget::TryFrom, input)
+}
+
 fn derive(target: DeriveTarget, input: DeriveInput) -> syn::Result<TokenStream> {
     let data_enum = match input.data {
         Data::Enum(data) => data,
@@ -129,18 +133,21 @@ fn derive(target: DeriveTarget, input: DeriveInput) -> syn::Result<TokenStream>
 #[derive(Clone, Copy, Debug)]
 enum DeriveTarget {
     Into,
+    TryFrom,
 }
 
 impl DeriveTarget {
     fn get_trait_name(&self) -> &'static str {
         match self {
             Self::Into => "Into",
+            Self::TryFrom => "TryFrom",
         }
     }
 
     fn get_helper_name(&self) -> &'static str {
         match self {
             Self::Into => "into",
+            Self::TryFrom => "try_from",
         }
     }
 }
@@ -186,6 +193,7 @@ fn derive_for_enum(
 ) -> TokenStream {
     let impl_fn = match target {
         DeriveTarget::Into => impl_into,
+        DeriveTarget::TryFrom => impl_try_from,
     };
 
     let qualified_repr_ty: syn::Path = parse_quote! { ::core::primitive::#repr_ty };
@@ -238,6 +246,54 @@ fn from(#param: #enum_ident) -> #input_ty {
         }
     }
 
+    fn impl_try_from(
+        enum_ident: &Ident,
+        variants: &[Ident],
+        repr_ty: &syn::Path,
+        input_ty: &ValidTy,
+    ) -> TokenStream {
+        let param = Ident::new("value", Span::call_site());
+
+        let overflow_assertion = emit_overflow_assert(enum_ident, variants, repr_ty, input_ty);
+        let emit_cast = |variant| {
+            let variant = ::quote::quote! { #enum_ident::#variant };
+            match input_ty {
+                ValidTy::Bounded(inner) => {
+                    let base_ty = inner.emit_qualified_base_ty();
+                    let expr = parse_quote! { #variant as #base_ty };
+                    inner.emit_new(&expr)
+                }
+                ValidTy::Primitive(ident) if ident == "bool" => {
+                    ::quote::quote! { ((#variant as #repr_ty) == 1) }
+                }
+                qualified @ ValidTy::Primitive(_) => ::quote::quote! { #variant as #qualified },
+            }
+        };
+
+        let clauses = variants.iter().map(|variant| {
+            let cast = emit_cast(variant);
+            ::quote::quote! {
+                if #param == #cast {
+                    ::core::result::Result::Ok(#enum_ident::#variant)
+                } else
+            }
+        });
+
+        ::quote::quote! {
+            #[automatically_derived]
+            impl ::core::convert::TryFrom<#input_ty> for #enum_ident {
+                type Error = ::kernel::prelude::Error;
+                fn try_from(#param: #input_ty) -> Result<#enum_ident, Self::Error> {
+                    #overflow_assertion
+
+                    #(#clauses)* {
+                        ::core::result::Result::Err(::kernel::prelude::EINVAL)
+                    }
+                }
+            }
+        }
+    }
+
     fn emit_overflow_assert(
         enum_ident: &Ident,
         variants: &[Ident],
@@ -360,6 +416,14 @@ fn emit_from_expr(&self, expr: &Expr) -> TokenStream {
         }
     }
 
+    fn emit_new(&self, expr: &Expr) -> TokenStream {
+        let Self { base_ty, bits, .. } = self;
+        let qualified_name: syn::Path = parse_str(Self::QUALIFIED_NAME).expect("valid path");
+        ::quote::quote! {
+            #qualified_name::<#base_ty, #bits>::new::<{ #expr }>()
+        }
+    }
+
     fn emit_qualified_base_ty(&self) -> TokenStream {
         let base_ty = &self.base_ty;
         ::quote::quote! { ::core::primitive::#base_ty }
diff --git a/rust/macros/lib.rs b/rust/macros/lib.rs
index 8842067d1017..893adecb9080 100644
--- a/rust/macros/lib.rs
+++ b/rust/macros/lib.rs
@@ -657,3 +657,179 @@ pub fn derive_into(input: TokenStream) -> TokenStream {
         .unwrap_or_else(syn::Error::into_compile_error)
         .into()
 }
+
+/// A derive macro for generating an implementation of the [`TryFrom`] trait.
+///
+/// This macro automatically derives the [`TryFrom`] trait for a given enum. Currently,
+/// it only supports [unit-only enum]s.
+///
+/// [unit-only enum]: https://doc.rust-lang.org/reference/items/enumerations.html#r-items.enum.unit-only
+///
+/// # Notes
+///
+/// - The macro generates [`TryFrom`] implementations that:
+///   - Return `Ok(VARIANT)` when the input corresponds to a variant.
+///   - Return `Err(EINVAL)` when the input does not correspond to any variant.
+///     (where `EINVAL` is from [`kernel::error::code`]).
+///
+/// - The macro uses the `try_from` custom attribute or `repr` attribute to generate
+///   [`TryFrom`] implementations. `try_from` always takes precedence over `repr`.
+///
+/// - Currently, the macro does not support `repr(C)` fieldless enums since the actual
+///   representation of discriminants is defined by rustc internally, and documentation
+///   around it is not yet settled. See [Rust issue #124403] and [Rust PR #147017]
+///   for more information.
+///
+/// - The macro generates a compile-time assertion for every variant to ensure its
+///   discriminant value fits within the type being converted from.
+///
+/// [`kernel::error::code`]: ../kernel/error/code/index.html
+/// [Rust issue #124403]: https://github.com/rust-lang/rust/issues/124403
+/// [Rust PR #147017]: https://github.com/rust-lang/rust/pull/147017
+///
+/// # Supported types in `#[try_from(...)]`
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
+/// the macro implements `TryFrom<isize>`:
+///
+/// [repr-rust]: https://doc.rust-lang.org/reference/items/enumerations.html#r-items.enum.discriminant.repr-rust
+///
+/// ```rust
+/// # use kernel::prelude::*;
+/// use kernel::macros::TryFrom;
+///
+/// #[derive(Debug, Default, PartialEq, TryFrom)]
+/// enum Foo {
+///     #[default]
+///     A,
+///     B = 0x7,
+/// }
+///
+/// assert_eq!(Err(EINVAL), Foo::try_from(-1_isize));
+/// assert_eq!(Ok(Foo::A), Foo::try_from(0_isize));
+/// assert_eq!(Ok(Foo::B), Foo::try_from(0x7_isize));
+/// assert_eq!(Err(EINVAL), Foo::try_from(0x8_isize));
+/// ```
+///
+/// ## With `#[repr(T)]`
+///
+/// The macro implements `TryFrom<T>`:
+///
+/// ```rust
+/// # use kernel::prelude::*;
+/// use kernel::macros::TryFrom;
+///
+/// #[derive(Debug, Default, PartialEq, TryFrom)]
+/// #[repr(u8)]
+/// enum Foo {
+///     #[default]
+///     A,
+///     B = 0x7,
+/// }
+///
+/// assert_eq!(Ok(Foo::A), Foo::try_from(0_u8));
+/// assert_eq!(Ok(Foo::B), Foo::try_from(0x7_u8));
+/// assert_eq!(Err(EINVAL), Foo::try_from(0x8_u8));
+/// ```
+///
+/// ## With `#[try_from(...)]`
+///
+/// The macro implements `TryFrom<T>` for each `T` specified in `#[try_from(...)]`,
+/// which always overrides `#[repr(...)]`:
+///
+/// ```rust
+/// # use kernel::prelude::*;
+/// use kernel::{
+///     macros::TryFrom,
+///     num::Bounded, //
+/// };
+///
+/// #[derive(Debug, Default, PartialEq, TryFrom)]
+/// #[try_from(bool, i16, Bounded<u8, 4>)]
+/// #[repr(u8)]
+/// enum Foo {
+///     #[default]
+///     A,
+///     B,
+/// }
+///
+/// assert_eq!(Err(EINVAL), Foo::try_from(-1_i16));
+/// assert_eq!(Ok(Foo::A), Foo::try_from(0_i16));
+/// assert_eq!(Ok(Foo::B), Foo::try_from(1_i16));
+/// assert_eq!(Err(EINVAL), Foo::try_from(2_i16));
+///
+/// assert_eq!(Ok(Foo::A), Foo::try_from(false));
+/// assert_eq!(Ok(Foo::B), Foo::try_from(true));
+///
+/// assert_eq!(Ok(Foo::A), Foo::try_from(Bounded::<u8, 4>::new::<0>()));
+/// assert_eq!(Ok(Foo::B), Foo::try_from(Bounded::<u8, 4>::new::<1>()));
+/// ```
+///
+/// ## Compile-time Overflow Assertion
+///
+/// The following examples do not compile:
+///
+/// ```compile_fail
+/// # use kernel::macros::TryFrom;
+/// #[derive(TryFrom)]
+/// #[try_from(u8)]
+/// enum Foo {
+///     // `256` is larger than `u8::MAX`.
+///     A = 256,
+/// }
+/// ```
+///
+/// ```compile_fail
+/// # use kernel::macros::TryFrom;
+/// #[derive(TryFrom)]
+/// #[try_from(u8)]
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
+/// # use kernel::macros::TryFrom;
+/// // Tuple-like enums or struct-like enums are not allowed.
+/// #[derive(TryFrom)]
+/// enum Foo {
+///     A(u8),
+///     B { inner: u8 },
+/// }
+/// ```
+///
+/// ```compile_fail
+/// # use kernel::macros::TryFrom;
+/// // Structs are not allowed.
+/// #[derive(TryFrom)]
+/// struct Foo(u8);
+/// ```
+///
+/// ```compile_fail
+/// # use kernel::macros::TryFrom;
+/// // `repr(C)` enums are not allowed.
+/// #[derive(TryFrom)]
+/// struct Foo(u8)
+/// ```
+#[proc_macro_derive(TryFrom, attributes(try_from))]
+pub fn derive_try_from(input: TokenStream) -> TokenStream {
+    let input = parse_macro_input!(input as DeriveInput);
+    convert::derive_try_from(input)
+        .unwrap_or_else(syn::Error::into_compile_error)
+        .into()
+}

-- 
2.52.0

