From: Nick Dowsett <nick42d@gmail.com>
Date: Sun, 22 Nov 2026 12:35:40 +0800
Subject: [PATCH 3/4] platform/x86: clevo-laptop: probe keyboard backlight
 type and detect 5-step white backlight
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-clevo-laptop-v1-3-881debf4d4b0@gmail.com>
References: <20261122-clevo-laptop-v1-0-881debf4d4b0@gmail.com>
In-Reply-To: <20261122-clevo-laptop-v1-0-881debf4d4b0@gmail.com>
To: Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>
Cc: Armin Wolf <W_Armin@gmx.de>, Werner Sembach <wse@tuxedocomputers.com>, 
 linux-kernel@vger.kernel.org, platform-driver-x86@vger.kernel.org, 
 rust-for-linux@vger.kernel.org, Nick Dowsett <nick42d@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795322140; l=6319;
 i=nick42d@gmail.com; h=from:subject:message-id;
 bh=zhmmGSNR3OSLrzhCCRTFeuk7Hl8QAWk96pymxiIpueQ=;
 b=yvR0HYD40/ncdu8Rn5vvHwCpW32+HFnym+lcwVUt/kQXf8VZqAtjZ/zw+rWOd5Q9J8uHsgisK
 23wRgPoV2+YDpdkCiVYPzx0Bzf6TkwdzJy0afKrKMCGMniDJIrPfdyd
X-Developer-Key: i=nick42d@gmail.com; a=ed25519;
 pk=1uIkNexEofzEXNN3Y3QW5z8IrgjWaP0yH6Es51jxWOg=
X-Endpoint-Received: by B4 Relay for nick42d@gmail.com/default with auth_id=1596
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

- Add `GetSpecs` and `GetBiosFeatures2` EC queries and `KbBacklightType`
  detection (with retries and BIOS features fallback for older devices).
- Restrict probe to the supported 5-step white keyboard backlight.

Signed-off-by: Nick Dowsett <nick42d@gmail.com>
---
 drivers/platform/x86/clevo-laptop.rs | 125 +++++++++++++++++++++++++++++++++++
 1 file changed, 125 insertions(+)

diff --git a/drivers/platform/x86/clevo-laptop.rs b/drivers/platform/x86/clevo-laptop.rs
index 289b30c478ec..6f08bf295c07 100644
--- a/drivers/platform/x86/clevo-laptop.rs
+++ b/drivers/platform/x86/clevo-laptop.rs
@@ -13,6 +13,10 @@
     device,
     dmi,
     prelude::*,
+    time::{
+        delay::fsleep,
+        Delta, //
+    },
     wmi, //
 };
 
@@ -24,7 +28,12 @@
 /// DMI board name allowlist, restricted to tested boards since the WMI GUID is not
 /// unique.
 const SUPPORTED_BOARDS: &[&CStr] = &[c"NLx0AU"];
+const CLEVO_EC_CMD_GET_SPECS: u8 = 0x0D;
 const CLEVO_EC_CMD_GET_BIOS_FEATURES_1: u8 = 0x52;
+const CLEVO_EC_CMD_GET_BIOS_FEATURES_2: u8 = 0x7A;
+const CLEVO_BIOS_FEATURE_CODE_WHITE_ONLY_KB: u32 = 0x4000_0000;
+const CLEVO_BIOS_FEATURE_CODE_3_ZONE_RGB_KB: u32 = 0x0040_0000;
+const CLEVO_BIOS_FEATURE_CODE_WHITE_ONLY_KB_MAX_5: u32 = 0x4000;
 const CLEVO_EC_WMI_INSTANCE: u8 = 0;
 
 module! {
@@ -89,6 +98,17 @@ fn probe<'bound>(
 
             backend.query(GetBiosFeatures1).map_err(|_| ENODEV)?;
 
+            // MVP: Only the NL57AU 5-step white backlight is supported.
+            if backend.detect_backlight_type()? != Some(KbBacklightType::FixedColor) {
+                return Err(ENODEV);
+            }
+            let has_white_5 = backend
+                .query(GetBiosFeatures2)
+                .is_ok_and(|feat2| feat2.has_white_only_kb_max_5());
+            if !has_white_5 {
+                return Err(ENODEV);
+            }
+
             Ok(try_pin_init!(WmiDriver {}))
         })
     }
@@ -127,6 +147,61 @@ fn query<Q>(&self, query: Q) -> Result<Q::Output>
             }
         }
     }
+    /// Detect backlight type e.g white.
+    fn detect_backlight_type(&self) -> Result<Option<KbBacklightType>> {
+        const MAX_RETRIES: usize = 3;
+        const RETRY_SLEEP_DURATION: Delta = Delta::from_millis(50);
+
+        for attempt in 0..MAX_RETRIES {
+            if attempt != 0 {
+                pr_debug!(
+                    "KbBacklightType::None probably wrong, retrying - attempt {} of {}\n",
+                    attempt,
+                    MAX_RETRIES - 1
+                );
+                fsleep(RETRY_SLEEP_DURATION);
+            }
+            if let Ok(specs) = self.query(GetSpecs) {
+                let backlight_type = specs.kb_backlight_type();
+                if backlight_type != Ok(None) {
+                    return backlight_type.map_err(|_| ENODEV);
+                }
+            }
+        }
+
+        // Check for devices <= Intel 8th gen (only white only, 3 zone RGB,
+        // or no backlight on these devices)
+        let feat1 = self.query(GetBiosFeatures1).map_err(|_| ENODEV)?;
+        if feat1.has_3_zone_rgb_kb() {
+            Ok(Some(KbBacklightType::ThreeZoneRgb))
+        } else if feat1.has_white_only_kb() {
+            Ok(Some(KbBacklightType::FixedColor))
+        } else {
+            Ok(None)
+        }
+    }
+}
+
+/// Keyboard backlight type - e.g Fixed Color
+#[derive(PartialEq)]
+#[repr(u8)]
+enum KbBacklightType {
+    FixedColor = 0x01,
+    ThreeZoneRgb = 0x02,
+    OneZoneRgb = 0x06,
+    PerKeyRgb = 0xF3,
+}
+impl KbBacklightType {
+    const fn from_raw(raw: u8) -> Result<Option<Self>, u8> {
+        match raw {
+            0x01 => Ok(Some(KbBacklightType::FixedColor)),
+            0x02 => Ok(Some(KbBacklightType::ThreeZoneRgb)),
+            0x06 => Ok(Some(KbBacklightType::OneZoneRgb)),
+            0xF3 => Ok(Some(KbBacklightType::PerKeyRgb)),
+            0x00 => Ok(None),
+            other => Err(other),
+        }
+    }
 }
 
 /// Args for a command sent to the EC.
@@ -144,8 +219,12 @@ fn as_bytes(&self) -> &[u8] {
     }
 }
 
+#[derive(Debug, Clone, Copy, PartialEq, Eq)]
+struct GetSpecs;
 #[derive(Debug, Clone, Copy, PartialEq, Eq)]
 struct GetBiosFeatures1;
+#[derive(Debug, Clone, Copy, PartialEq, Eq)]
+struct GetBiosFeatures2;
 
 impl EcQuery for GetBiosFeatures1 {
     type Output = BiosFeatures1;
@@ -163,10 +242,56 @@ fn deserialize_output(output: &[u8]) -> Result<Self::Output> {
         Ok(feat)
     }
 }
+impl EcQuery for GetBiosFeatures2 {
+    type Output = BiosFeatures2;
+    fn cmd(&self) -> u8 {
+        CLEVO_EC_CMD_GET_BIOS_FEATURES_2
+    }
+    fn args(&self) -> EcMethodArgs {
+        EcMethodArgs::Scalar(0)
+    }
+    fn deserialize_output(output: &[u8]) -> Result<Self::Output> {
+        let (feat, _) = BiosFeatures2::read_from_prefix(output).map_err(|_| ENODATA)?;
+        Ok(feat)
+    }
+}
+impl EcQuery for GetSpecs {
+    type Output = Specs;
+    fn cmd(&self) -> u8 {
+        CLEVO_EC_CMD_GET_SPECS
+    }
+    fn args(&self) -> EcMethodArgs {
+        EcMethodArgs::Scalar(0)
+    }
+    fn deserialize_output(output: &[u8]) -> Result<Self::Output> {
+        let (specs, _) = Specs::read_from_prefix(output).map_err(|_| ENODATA)?;
+        Ok(specs)
+    }
+}
 
 #[derive(Debug, Clone, Copy, PartialEq, Eq, FromBytes)]
 struct BiosFeatures1(u32);
+#[derive(Debug, Clone, Copy, PartialEq, Eq, FromBytes)]
+struct BiosFeatures2(u32);
+#[derive(Debug, Clone, Copy, PartialEq, Eq, FromBytes)]
+struct Specs([u8; 16]);
 
 impl BiosFeatures1 {
     const INVALID: Self = Self(0xFFFF_FFFF);
+    const fn has_white_only_kb(self) -> bool {
+        (self.0 & CLEVO_BIOS_FEATURE_CODE_WHITE_ONLY_KB) != 0
+    }
+    const fn has_3_zone_rgb_kb(self) -> bool {
+        (self.0 & CLEVO_BIOS_FEATURE_CODE_3_ZONE_RGB_KB) != 0
+    }
+}
+impl BiosFeatures2 {
+    const fn has_white_only_kb_max_5(self) -> bool {
+        (self.0 & CLEVO_BIOS_FEATURE_CODE_WHITE_ONLY_KB_MAX_5) != 0
+    }
+}
+impl Specs {
+    const fn kb_backlight_type(&self) -> Result<Option<KbBacklightType>, u8> {
+        KbBacklightType::from_raw(self.0[0x0F])
+    }
 }

-- 
2.56.1

