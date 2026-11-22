From: Nick Dowsett <nick42d@gmail.com>
Date: Sun, 22 Nov 2026 12:35:39 +0800
Subject: [PATCH 2/4] platform/x86: clevo-laptop: add EC WMI query interface
 and BIOS feature check
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-clevo-laptop-v1-2-881debf4d4b0@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795322140; l=4496;
 i=nick42d@gmail.com; h=from:subject:message-id;
 bh=EPKNfrbkINZpqJuaFZ3pMA8YKpq/n10Zk87rakX3Q7k=;
 b=uw5Rn7jXoU00duppx5D21qAg0OfXBZjgW/qqa3ysThTq2dLQVxjgnkts4rkrqLMNvu8HujExs
 MFeKLSOZXTPBbJFihKx83xSn1X2mvk3RXgEHKsxxww0LQCSu/6jWl0c
X-Developer-Key: i=nick42d@gmail.com; a=ed25519;
 pk=1uIkNexEofzEXNN3Y3QW5z8IrgjWaP0yH6Es51jxWOg=
X-Endpoint-Received: by B4 Relay for nick42d@gmail.com/default with auth_id=1596
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

- Add `EcQuery` trait and implement `EcInterface` for sending commands to
  the Clevo EC over WMI.
- Add `GetBiosFeatures1` query to verify the EC responds during probe.

Signed-off-by: Nick Dowsett <nick42d@gmail.com>
---
 drivers/platform/x86/clevo-laptop.rs | 104 ++++++++++++++++++++++++++++++++++-
 1 file changed, 102 insertions(+), 2 deletions(-)

diff --git a/drivers/platform/x86/clevo-laptop.rs b/drivers/platform/x86/clevo-laptop.rs
index 1d862c57b3fe..289b30c478ec 100644
--- a/drivers/platform/x86/clevo-laptop.rs
+++ b/drivers/platform/x86/clevo-laptop.rs
@@ -24,6 +24,8 @@
 /// DMI board name allowlist, restricted to tested boards since the WMI GUID is not
 /// unique.
 const SUPPORTED_BOARDS: &[&CStr] = &[c"NLx0AU"];
+const CLEVO_EC_CMD_GET_BIOS_FEATURES_1: u8 = 0x52;
+const CLEVO_EC_WMI_INSTANCE: u8 = 0;
 
 module! {
     type: ClevoLaptopModule,
@@ -33,6 +35,21 @@
     license: "GPL",
 }
 
+/// Represents a query that can run on the Clevo Embedded Controller (EC).
+///
+/// # Endianness note
+/// Clevo EC sends and receives little endian data.
+/// As this is a `platform/x86` driver, no conversion is required.
+trait EcQuery {
+    type Output;
+    /// EC method code.
+    fn cmd(&self) -> u8;
+    /// EC method args.
+    fn args(&self) -> EcMethodArgs;
+    /// Each command must know how to deserialize itself from the raw EC output.
+    fn deserialize_output(output: &[u8]) -> Result<Self::Output>;
+}
+
 /// RAII guard for Clevo Laptop Module holding all subsystem drivers e.g WMI.
 #[pin_data]
 struct ClevoLaptopModule {
@@ -65,8 +82,91 @@ impl wmi::Driver for WmiDriver {
     type Data<'bound> = WmiDriver;
     const ID_TABLE: wmi::IdTable = &WMI_TABLE;
     fn probe<'bound>(
-        _dev: &'bound wmi::Device<device::Core<'_>>,
+        dev: &'bound wmi::Device<device::Core<'_>>,
     ) -> impl PinInit<Self::Data<'bound>, Error> + 'bound {
-        try_pin_init!(WmiDriver {})
+        pin_init::pin_init_scope(move || {
+            let backend = EcInterface::Wmi(dev);
+
+            backend.query(GetBiosFeatures1).map_err(|_| ENODEV)?;
+
+            Ok(try_pin_init!(WmiDriver {}))
+        })
+    }
+}
+
+/// Interface to Clevo Embedded Controller.
+enum EcInterface<'a> {
+    Wmi(&'a wmi::Device<device::Bound>),
+}
+impl<'a> EcInterface<'a> {
+    /// Send a query to the EC, receiving a response.
+    fn query<Q>(&self, query: Q) -> Result<Q::Output>
+    where
+        Q: EcQuery + core::fmt::Debug,
+        Q::Output: core::fmt::Debug,
+    {
+        let cmd = query.cmd();
+        let arg = query.args();
+
+        match self {
+            Self::Wmi(wdev) => {
+                dev_dbg!(
+                    wdev.as_ref(),
+                    "ec cmd {query:?} method_id 0x{cmd:02x} arg {arg:x?}\n"
+                );
+                let buf = wdev.invoke_method(
+                    CLEVO_EC_WMI_INSTANCE,
+                    cmd.into(),
+                    arg.as_bytes(),
+                    core::mem::size_of::<Q::Output>(),
+                )?;
+
+                let res = Q::deserialize_output(&buf)?;
+                dev_dbg!(wdev.as_ref(), "ec cmd {query:?} -> {res:?}\n");
+                Ok(res)
+            }
+        }
     }
 }
+
+/// Args for a command sent to the EC.
+#[derive(Debug)]
+enum EcMethodArgs {
+    Scalar(u32),
+}
+impl EcMethodArgs {
+    /// Convert to the type expected by the EC.
+    fn as_bytes(&self) -> &[u8] {
+        match self {
+            // Clevo EC expects little-endian integers; x86 is always little-endian.
+            Self::Scalar(val) => val.as_bytes(),
+        }
+    }
+}
+
+#[derive(Debug, Clone, Copy, PartialEq, Eq)]
+struct GetBiosFeatures1;
+
+impl EcQuery for GetBiosFeatures1 {
+    type Output = BiosFeatures1;
+    fn cmd(&self) -> u8 {
+        CLEVO_EC_CMD_GET_BIOS_FEATURES_1
+    }
+    fn args(&self) -> EcMethodArgs {
+        EcMethodArgs::Scalar(0)
+    }
+    fn deserialize_output(output: &[u8]) -> Result<Self::Output> {
+        let (feat, _) = BiosFeatures1::read_from_prefix(output).map_err(|_| ENODATA)?;
+        if feat == BiosFeatures1::INVALID {
+            return Err(ENODEV);
+        }
+        Ok(feat)
+    }
+}
+
+#[derive(Debug, Clone, Copy, PartialEq, Eq, FromBytes)]
+struct BiosFeatures1(u32);
+
+impl BiosFeatures1 {
+    const INVALID: Self = Self(0xFFFF_FFFF);
+}

-- 
2.56.1

