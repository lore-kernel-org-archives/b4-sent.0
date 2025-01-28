From: Timothy Garwood <gtimothy-dev@protonmail.com>
Date: Tue, 28 Jan 2025 16:48:18 +0100
Subject: [PATCH RFC WIP v2] rust: add bitfield_options macro to create
 bitfield wrapper types
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250128-add-bitfield-options-macro-v2-1-d65349b389fc@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAEH8mGcC/32NywrCMBREf6XctZEkfdi6EgTBnbhxIV3cJqm90
 DYlCUUp/XdjP8DVMMNhzgLeODIejskCzszkyY6xyF0CqsPxZRjp2EFymQnBS4Zas4ZCS6bXzE4
 h8p4NqJxlWGaHJq0qwREhHkzOtPTezp9wv5x/2+N6gzpmRz5Y99m8s9iIqMi5kPk/xSyYYNgWa
 Kq0KAvVnCZngx0HpH6v7AD1uq5f/bC2ONUAAAA=
X-Change-ID: 20241108-add-bitfield-options-macro-a847b39910aa
To: Miguel Ojeda <ojeda@kernel.org>, Alex Gaynor <alex.gaynor@gmail.com>
Cc: Boqun Feng <boqun.feng@gmail.com>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <benno.lossin@proton.me>, 
 Andreas Hindborg <a.hindborg@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 Trevor Gross <tmgross@umich.edu>, linux-kernel@vger.kernel.org, 
 rust-for-linux@vger.kernel.org, 
 Timothy Garwood <gtimothy-dev@protonmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1738079350; l=18684;
 i=gtimothy-dev@protonmail.com; s=20250123; h=from:subject:message-id;
 bh=WQAJcDGLKe/OoYu6dkrvdXRnrr8OYrL9iesYH3b6znw=;
 b=D+ZDZFtW1Ds8UBThyKct0JchgM1IRhPoXDNKc9j0DnlFUqebW6NIcSg4vvEidtcszScHChvf2
 cJMzvfWOcpsAImpa8YSkmxnmcsaqDFOqeF2vEhzR0WnCz/+6zihzLBN
X-Developer-Key: i=gtimothy-dev@protonmail.com; a=ed25519;
 pk=4MkQh/a3f6vfOYMYyJPEDyETzhXD/Sa4ZNZ/kAKxOOs=
X-Endpoint-Received: by B4 Relay for gtimothy-dev@protonmail.com/20250123 with auth_id=330
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

- implement a macro to generate a bitfield wrapper with macro-specified
  methods to set and unset macro-specified flags.
- introduce a Bitfield trait to access the field

The macro also generates a `Default` implementation for the wrapper
type, which instantiates a wrapped bitfield as if created with all
methods called with `false`.

The macro also generates a `TryFrom<wrapped_bitfield>` implementation
for the wrapper that prevents instantiating a bitfield wrapper with an
invalid field.

Signed-off-by: Timothy Garwood <gtimothy-dev@protonmail.com>
---
Hello all,

There was some discussion about handling bitfield C enums and
bitfield-like C enums in a safe manner in the "Best way to handle
enum/flags situation"[1] zulip discussion about the HRTIMER_MODE enum in
`include/linux/hrtimer.h`.

I will define *bitfield* as a bit set where
 - different flags set different bits (no overlap),
 - all flags are additive (there are no invalid combination of flags),
 - all flags are optional.

I will define *bitfield-like* in the context of the HRTIMER_MODE
bitfield-LIKE C enum as a bit set where:
 - different BASE flags set different bits (no overlap) but there are
   aliases for some flag combinations, and some aliases are equal to a
   base case (HRTIMER_MODE_ABS_PINNED == HRTIMER_MODE_PINNE because
   HRTIMER_MODE_ABS==0x00),
 - not all flags are additive, there may invalid combination of flags:
   - HRTIMER_MODE_SOFT and HRTIMER_MODE_HARD (if I am not mistaken)
   - HRTIMER_MODE_ABS and HRTIMER_MODE_REL (though this one is mitigated
     by the fact that ABS is 0x00 therefore ABS|REL==REL)

Issues:
As the case of HRTIMER_MODE shows, sometimes the valid and invalid
combinations are not semantically incoded in the structure. In order to
manipulate such a field safely in Rust, we can wrap it in a type
that prevents the user from reaching an invalid bitfield state before we
use it in C code.

Additionally, 'well formed' bitfield C enums are not marked as such,
distinguishing them from normal C enums in a way that would allow for a
specific bindgen solution.

Possible solutions:
 - C centered solution: refactor bitfield enums in the kernel to
   respects the first definition and 'annotate them' in a way that would
   allow a custom bindgen conversion to a Rust bitfield wrapper
 - Rust cented solution: define a rust macro that builds a bitfield
   wrapper implementing flag setting methods like `std::fs::OpenOptions`
   by taking as input some semantic information.
   Call this macro by hand with the proper semantic information to use
   that C enum in Rust.

Here is a Rust macro solution that generate such a wrapper:
1. It generates methods like OpenOptions' to set/unset flags.
2. It handle invalid flag pairs by unsetting the one before setting the
   other.
3. It permits flags that set/unset more than one bit at a time (this may
   be a mistake, but in case the C bitfield enum does it too).
4. It implements the Default trait.
5. It implements the TryFrom<field_type> trait to attempt instantiation
   from a passed bitfield.

I am requesting comments, any issues/suggestions? I have some questions
myself:
 - should the macro take in a :
   ```
   <#optional_attributes>
   <visibility> <wrapper_name>(<field_type>);
   ```
   instead of the current `name:<wrapper_name>` and `type:<field_type>`
   entries?
   It might be better since it allows one to decorate the wrapper with
   desired attributes.
 - 3. may be a mistake. We could handle only single-bit flags and pass
   the bit offset instead to the macro for each flag and its optional
   counterflag.
 - I created a Bitfield trait providing a bits() function, but the
   bits() function could also simply be part of the wrapper's impl.
   Thoughts?

Thanks in advance for any feedback,
Timothy

Link:
https://rust-for-linux.zulipchat.com/#narrow/channel/291565-Help/topic/Best.20way.20to.20handle.20enum.2Fflags.20situation
[1]
---
Changes in v2:
- removed a v1 question answered by Miguel Ojeda
- fix code formatting and typos
- added expanded macro section to the macro documentation
- added Copy, Clone trait derivation on wrappers
- changed commit authorship and Signed-off-by to a "known identity"
- Link to v1:
https://lore.kernel.org/r/20250125-add-bitfield-options-macro-v1-1-af6ae93686cb@protonmail.com
---
 rust/kernel/bitfield.rs | 396 ++++++++++++++++++++++++++++++++++++++++++++++++
 rust/kernel/lib.rs      |   1 +
 2 files changed, 397 insertions(+)

diff --git a/rust/kernel/bitfield.rs b/rust/kernel/bitfield.rs
new file mode 100644
index 0000000000000000000000000000000000000000..d8ae33826359a37a9c9e4306eb55845e08aa0b00
--- /dev/null
+++ b/rust/kernel/bitfield.rs
@@ -0,0 +1,396 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! Trait and macro to build bitfield wrappers.
+//!
+//! A trait and [`kernel::bitfield_options`] macro to build bitfield wrappers with
+//! [`std::fs::OpenOptions`](https://doc.rust-lang.org/std/fs/struct.OpenOptions.html)-like methods to
+//! set bits and _try to ensure an always-valid state_.
+
+/// A trait associating a bitfield type to a wrapper type to allow for shared trait implementations
+/// and bitfield retrieval.
+pub trait BitField {
+    /// The bitfield type, usually `u8` or `u32`
+    type Bits;
+
+    /// returns the bits stored by the wrapper.
+    fn bits(&self) -> Self::Bits;
+}
+
+/// concatenate sequences using a comma separator. Uses a a `, and` (oxford comma) separation
+/// instead between the last two items.
+#[doc(hidden)]
+#[macro_export]
+macro_rules! concat_with_oxford_comma {
+    ($last:expr) => (concat!("and ", $last));
+    ($left:expr, $($right:expr),+ ) => (
+        concat!($left, ", ", $crate::concat_with_oxford_comma!($($right),+))
+    )
+}
+
+/// Builds a bitfield wrapper with
+/// [`std::fs::OpenOptions`](https://doc.rust-lang.org/std/fs/struct.OpenOptions.html)-like methods to
+/// set bits.
+///
+/// This wrapper _tries to ensure an always-valid state_, even when created from a bitfield
+/// directly.
+///
+/// The wrapper implements the [`BitField`] trait.
+///
+/// # argument types
+///   - `name`: the name of the wrapper to build.
+///   - `type`: the bit field type, usually `u32` or `u8`. Must be an int primitive.
+///   - `options`: array of `{ name:ident, true:expr, false:expr }` options where name is the name
+///     of a method that will set the `true:expr` bit(s) when called with `true` or else the
+///     `false:expr` bit(s). In a standard bitfield, `false:expr` is set to `false:0`, but sometimes
+///     different bit flags designate incompatible alternatives : in these cases, set `false` to
+///     activate the alternative bit(s).
+///
+/// # Examples
+///
+/// Call the macro to create the bitflag wrapper.
+///
+/// Here we create a wrapper that allows to set `RED`, `BLUE`, `GREEN` bits independently,
+/// and additionally either the `BIG` bit or the `SMALL` bit.
+///
+/// `BIG` and `SMALL` are incompatible alternatives.
+///
+/// ```rust
+/// use kernel::bitfield_options;
+///
+/// const BIG: u32 = 16;
+/// const SMALL: u32 = 1;
+///
+/// const RED: u32 = 2;
+/// const GREEN: u32 = 4;
+/// const BLUE: u32 = 8;
+///
+/// bitfield_options! {
+///     name: SizeAndColors,
+///     type: u32,
+///     options: [
+///         {name:big, true:BIG, false:SMALL},
+///         {name:red, true:RED, false:0u32},
+///         {name:blue, true:BLUE, false:0u32},
+///         {name:green, true:GREEN, false:0u32}
+///     ]
+/// };
+/// ```
+///
+/// The `SizeAndColor` type is now available in this scope.
+///
+/// It implements the [`Default`] trait where all options are set to `false`:
+///
+/// ```rust
+/// # use kernel::bitfield_options;
+/// # use kernel::bitfield::BitField; // to have access to the bits() method
+/// #
+/// # const BIG: u32 = 16;
+/// # const SMALL: u32 = 1;
+/// #
+/// # const RED: u32 = 2;
+/// # const GREEN: u32 = 4;
+/// # const BLUE: u32 = 8;
+/// #
+/// # bitfield_options! {
+/// #     name: SizeAndColors,
+/// #     type: u32,
+/// #     options: [
+/// #         {name:big, true:BIG, false:SMALL},
+/// #         {name:red, true:RED, false:0u32},
+/// #         {name:blue, true:BLUE, false:0u32},
+/// #         {name:green, true:GREEN, false:0u32}
+/// #     ]
+/// # };
+/// let sac = SizeAndColors::default();
+///
+/// // the default state, with all the options set to false should be the field with only the
+/// // `SMALL` bit(s) set
+/// assert_eq!(
+///     sac.bits(),
+///     SMALL | 0u32 | 0u32 | 0u32)
+/// ```
+///
+/// It implements the [`TryFrom`] trait which succeeds only if the passed bitfield is a valid state:
+///
+/// ```rust
+/// # use kernel::bitfield_options;
+/// #
+/// # const BIG: u32 = 16;
+/// # const SMALL: u32 = 1;
+/// #
+/// # const RED: u32 = 2;
+/// # const GREEN: u32 = 4;
+/// # const BLUE: u32 = 8;
+/// #
+/// # bitfield_options! {
+/// #     name: SizeAndColors,
+/// #     type: u32,
+/// #     options: [
+/// #         {name:big, true:BIG, false:SMALL},
+/// #         {name:red, true:RED, false:0u32},
+/// #         {name:blue, true:BLUE, false:0u32},
+/// #         {name:green, true:GREEN, false:0u32}
+/// #     ]
+/// # };
+/// # let sac = SizeAndColors::default();
+/// let small_and_no_colors = SizeAndColors::try_from(SMALL)
+///    .expect("having only the SMALL bit to 1 should be a valid state");
+///
+/// // Having only the `SMALL` bit set to 1 is the default state.
+/// assert_eq!(sac, small_and_no_colors);
+///
+/// let big_and_rgb = SizeAndColors::try_from(BIG | RED | GREEN | BLUE)
+///     .expect("having the BIG, RED, GREEN and BLUE bits set to 1 should be a valid state");
+///
+/// assert_eq!(
+///     SizeAndColors::default()
+///         .big(true)
+///         .red(true)
+///         .blue(true)
+///         .green(true),
+///     big_and_rgb
+/// );
+///
+/// let big_and_small = SizeAndColors::try_from(BIG | SMALL)
+///     .expect_err("BIG and SMALL are incompatible, this should fail");
+///
+/// let intense:u32 = 1024;
+/// let big_and_intense = SizeAndColors::try_from(BIG | intense)
+///     .expect_err("BIG|intense is not a valid state, this should fail");
+/// ```
+///
+/// To achieve this, the macro expands to this:
+///
+/// ```ignore
+/// # use kernel::bitfield_options;
+/// #
+/// # const BIG: u32 = 16;
+/// # const SMALL: u32 = 1;
+/// #
+/// # const RED: u32 = 2;
+/// # const GREEN: u32 = 4;
+/// # const BLUE: u32 = 8;
+/// #[doc = concat!("A wrapper around a `",stringify!(u32),
+/// "` bitfield that sets bitflags using its ",crate::concat_with_oxford_comma!(
+/// concat!("[`",stringify!(big),"`](",stringify!(SizeAndColors),"::",stringify!(big),")"),
+/// concat!("[`",stringify!(red),"`](",stringify!(SizeAndColors),"::",stringify!(red),")"),
+/// concat!("[`",stringify!(blue),"`](",stringify!(SizeAndColors),"::",stringify!(blue),")"),
+/// concat!("[`",stringify!(green),"`](",stringify!(SizeAndColors),"::",stringify!(green),")")),
+/// " methods.")]
+/// #[derive(Debug, PartialEq)]
+/// pub struct SizeAndColors(u32);
+///
+/// impl crate::bitfield::BitField for SizeAndColors {
+///     type Bits = u32;
+///     fn bits(&self) -> Self::Bits {
+///         self.0
+///     }
+/// }
+/// impl SizeAndColors {
+///     #[doc = concat!("if `true`, unsets the `",stringify!(SMALL),
+///     "` bit(s) and sets the `",stringify!(BIG),"` bit(s).  ")]
+///     #[doc = "Otherwise, does the opposite."]
+///     pub fn big(mut self, big: bool) -> Self {
+///         if big {
+///             self.0 = self.0 & !SMALL | BIG;
+///         } else {
+///             self.0 = self.0 & !BIG | SMALL;
+///         }
+///         self
+///     }
+///     #[doc = concat!("if `true`, unsets the `",stringify!(0u32),
+///     "` bit(s) and sets the `",stringify!(RED),"` bit(s).  ")]
+///     #[doc = "Otherwise, does the opposite."]
+///     pub fn red(mut self, red: bool) -> Self {
+///         if red {
+///             self.0 = self.0 & !0u32 | RED;
+///         } else {
+///             self.0 = self.0 & !RED | 0u32;
+///         }
+///         self
+///     }
+///     #[doc = concat!("if `true`, unsets the `",stringify!(0u32),
+///     "` bit(s) and sets the `",stringify!(BLUE),"` bit(s).  ")]
+///     #[doc = "Otherwise, does the opposite."]
+///     pub fn blue(mut self, blue: bool) -> Self {
+///         if blue {
+///             self.0 = self.0 & !0u32 | BLUE;
+///         } else {
+///             self.0 = self.0 & !BLUE | 0u32;
+///         }
+///         self
+///     }
+///     #[doc = concat!("if `true`, unsets the `",stringify!(0u32),
+///     "` bit(s) and sets the `",stringify!(GREEN),"` bit(s).  ")]
+///     #[doc = "Otherwise, does the opposite."]
+///     pub fn green(mut self, green: bool) -> Self {
+///         if green {
+///             self.0 = self.0 & !0u32 | GREEN;
+///         } else {
+///             self.0 = self.0 & !GREEN | 0u32;
+///         }
+///         self
+///     }
+/// }
+/// impl Default for SizeAndColors {
+///     fn default() -> Self {
+///         Self(0).big(false).red(false).blue(false).green(false)
+///     }
+/// }
+/// impl TryFrom<<SizeAndColors as crate::bitfield::BitField>::Bits> for SizeAndColors {
+///     type Error = <SizeAndColors as crate::bitfield::BitField>::Bits;
+///     fn try_from(
+///         value: <SizeAndColors as crate::bitfield::BitField>::Bits,
+///     ) -> Result<Self, Self::Error> {
+///         let mut to_process = value.clone();
+///         let mut matched = false;
+///         for flag in [BIG, SMALL] {
+///             if (flag & to_process) == flag {
+///                 matched = true;
+///                 to_process -= flag;
+///                 if flag > 0 {
+///                     break;
+///                 }
+///             }
+///         }
+///         if !matched {
+///             return Err(value);
+///         }
+///         matched = false;
+///         for flag in [RED, 0u32] {
+///             if (flag & to_process) == flag {
+///                 matched = true;
+///                 to_process -= flag;
+///                 if flag > 0 {
+///                     break;
+///                 }
+///             }
+///         }
+///         if !matched {
+///             return Err(value);
+///         }
+///         matched = false;
+///         for flag in [BLUE, 0u32] {
+///             if (flag & to_process) == flag {
+///                 matched = true;
+///                 to_process -= flag;
+///                 if flag > 0 {
+///                     break;
+///                 }
+///             }
+///         }
+///         if !matched {
+///             return Err(value);
+///         }
+///         matched = false;
+///         for flag in [GREEN, 0u32] {
+///             if (flag & to_process) == flag {
+///                 matched = true;
+///                 to_process -= flag;
+///                 if flag > 0 {
+///                     break;
+///                 }
+///             }
+///         }
+///         if !matched {
+///             return Err(value);
+///         }
+///         if to_process == 0 {
+///             return Ok(Self(value));
+///         }
+///         return Err(value);
+///     }
+/// }
+/// ```
+#[macro_export]
+macro_rules! bitfield_options {{
+    name:$name:ident,
+    type:$t:ty,
+    options:[
+        $({name:$fn_name:ident, true: $true_bitval:expr, false: $false_bitval:expr}),+
+]} => {
+    #[doc = concat!("A wrapper around a `",
+        stringify!($t),
+        "` bitfield that sets bitflags using its ",
+        $crate::concat_with_oxford_comma!(
+        $(concat!("[`",
+            stringify!($fn_name),
+            "`](",
+            stringify!($name),
+            "::",
+            stringify!($fn_name),
+            ")")
+        ),+),
+        " methods.")]
+    #[derive(Clone, Copy, Debug, PartialEq)]
+    pub struct $name($t);
+
+    impl $crate::bitfield::BitField for $name {
+        type Bits = $t;
+
+        fn bits(&self) -> Self::Bits {
+            self.0
+        }
+    }
+
+    impl $name {
+    $(
+        #[doc = concat!("if `true`, unsets the `",
+            stringify!($false_bitval),
+            "` bit(s) and sets the `",
+            stringify!($true_bitval),
+            "` bit(s).  "
+        )]
+        #[doc = "Otherwise, does the opposite."]
+        pub fn $fn_name(mut self, $fn_name:bool)->Self{
+            if $fn_name{
+                self.0 = self.0 & !$false_bitval | $true_bitval;
+            }else{
+                self.0 = self.0 & !$true_bitval | $false_bitval;
+            }
+            self
+        }
+    )+
+    }
+
+    impl Default for $name{
+        fn default() -> Self {
+            Self(0)$(.$fn_name(false))+
+        }
+    }
+
+    impl TryFrom<<$name as $crate::bitfield::BitField>::Bits> for $name {
+        type Error = <$name as $crate::bitfield::BitField>::Bits;
+
+        fn try_from(value: <$name as $crate::bitfield::BitField>::Bits) -> Result<Self, Self::Error>
+        {
+            let mut to_process = value.clone();
+
+            let mut $(
+            matched = false;
+
+            for flag in [$true_bitval, $false_bitval] {
+                if (flag & to_process) == flag {
+                    matched = true;
+                    to_process -= flag;
+                    if flag > 0 {
+                        break;
+                    }
+                }
+            }
+            if !matched {
+                return Err(value);
+            })+
+
+
+            if to_process == 0 {
+                return Ok(Self(value));
+            }
+            return Err(value)
+        }
+    }
+
+    };
+}
+#[doc(inline)]
+pub use bitfield_options;
diff --git a/rust/kernel/lib.rs b/rust/kernel/lib.rs
index 545d1170ee6358e185b48ce10493fc61c646155c..2428a55dca09d3c75153ccfe135a3d1dae77862e 100644
--- a/rust/kernel/lib.rs
+++ b/rust/kernel/lib.rs
@@ -31,6 +31,7 @@
 pub use ffi;
 
 pub mod alloc;
+pub mod bitfield;
 #[cfg(CONFIG_BLOCK)]
 pub mod block;
 #[doc(hidden)]

---
base-commit: ceff0757f5dafb5be5205988171809c877b1d3e3
change-id: 20241108-add-bitfield-options-macro-a847b39910aa

Best regards,
-- 
Timothy Garwood <gtimothy-dev@protonmail.com>

