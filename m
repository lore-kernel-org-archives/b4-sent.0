From: Markus Probst <markus.probst@posteo.de>
Date: Sun, 29 Mar 2026 20:02:17 +0200
Subject: [PATCH v5 3/4] rust: add visibility to of_device_table macro
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260329-synology_microp_initial-v5-3-27cb80bdf591@posteo.de>
References: <20260329-synology_microp_initial-v5-0-27cb80bdf591@posteo.de>
In-Reply-To: <20260329-synology_microp_initial-v5-0-27cb80bdf591@posteo.de>
To: Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, Lee Jones <lee@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Miguel Ojeda <ojeda@kernel.org>, 
 Boqun Feng <boqun@kernel.org>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Len Brown <lenb@kernel.org>, 
 Saravana Kannan <saravanak@kernel.org>
Cc: platform-driver-x86@vger.kernel.org, linux-leds@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 rust-for-linux@vger.kernel.org, linux-acpi@vger.kernel.org, 
 Markus Probst <markus.probst@posteo.de>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1069;
 i=markus.probst@posteo.de; h=from:subject:message-id;
 bh=iV2l67bhv+wCuyTeTqB9BVUr9sNOMqsg1qsymLG7EsM=;
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBpyWk80jz8hwYduy2NVO16Nw+QmCcnfOUz4un+D
 flz7346mdyJAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCaclpPBsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMSwyLDIACgkQNHYf+OetQ9L1IhAAmOHqW05kUkziFxXtscbD5JGUieX/6Xe
 ONLSKTl/BtzYFwSZZOnvkhewlw5jN/37XUDGkFdu8ol6LY8XRd5hff+AV3JpM0oclvwbMOQABRc
 4gi67cvMB8iOGnIRN1/YcJl4NLbbyfYkugxE7CSF8wwnhRdOTzK7lyBLVPQUMg7OUpcijlEn92w
 85BW3OVkrRd19axOEFPR+Rkj0fOncuHqXiE5LWxmhrVJV5FPB/ylysA2sWHzZ9Y93ozYaF00iIX
 0Lbjeg8TkNnqesjS6D104WW7rBSMeV40f5cQr+RWqid3jDvc0h20sM0Aj73FDG+C5pwgI/DIaIV
 T+joE6ZUQb+GaVBLRjBlxmYk/rDzfQYuS6qhLd/DFq15Qd9S6V++H4kUJfTl0dZLfzAgmJpJE0y
 saDHowfRam5yf2gSWRPbnYOL0PNDaivmi6ppJG4sdcb7OlHiYTJ83meAJTfoIYY8gu8h2sKwH3p
 jtfjoOj11bGwZMQubldnHPl10SyA6ABxrqB2RzX2CzV7BLEvWxOgenRXq0uXeVXaF8Gikp+AwRL
 qsqVm8hkZpDXLiQIUK+ShWyZlibpj34PM2u7xg5x0MPOEcYmcta2rfgrZX2NuxipHvJtabHUEeN
 OCJE7QzLwafk3BsbFSqdnzgFvEXMeDIkZhQBggpkMJmKaNoV9hzk=
X-Developer-Key: i=markus.probst@posteo.de; a=openpgp;
 fpr=827418C4F4AC58E77230C47334761FF8E7AD43D2
X-Endpoint-Received: by B4 Relay for markus.probst@posteo.de/default with auth_id=680
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add visibility argument to macro to allow defining an of device table in
a different module than the driver, which can improve readability.

Signed-off-by: Markus Probst <markus.probst@posteo.de>
---
 rust/kernel/of.rs | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/rust/kernel/of.rs b/rust/kernel/of.rs
index 58b20c367f99..a0de98a23416 100644
--- a/rust/kernel/of.rs
+++ b/rust/kernel/of.rs
@@ -53,8 +53,9 @@ pub const fn new(compatible: &'static CStr) -> Self {
 /// Create an OF `IdTable` with an "alias" for modpost.
 #[macro_export]
 macro_rules! of_device_table {
-    ($table_name:ident, $module_table_name:ident, $id_info_type: ty, $table_data: expr) => {
-        const $table_name: $crate::device_id::IdArray<
+    ($table_vis:vis $table_name:ident, $module_table_name:ident, $id_info_type: ty,
+        $table_data: expr) => {
+        $table_vis const $table_name: $crate::device_id::IdArray<
             $crate::of::DeviceId,
             $id_info_type,
             { $table_data.len() },

-- 
2.52.0

