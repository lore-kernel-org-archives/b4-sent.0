From: Manas <manas18244@iiitd.ac.in>
Date: Mon, 18 Nov 2024 18:42:17 +0530
Subject: [PATCH v2 1/3] rust: block: simplify Result<()> in
 validate_block_size return
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241118-simplify-result-v2-1-9d280ada516d@iiitd.ac.in>
References: <20241118-simplify-result-v2-0-9d280ada516d@iiitd.ac.in>
In-Reply-To: <20241118-simplify-result-v2-0-9d280ada516d@iiitd.ac.in>
To: FUJITA Tomonori <fujita.tomonori@gmail.com>, 
 Trevor Gross <tmgross@umich.edu>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Andreas Hindborg <a.hindborg@kernel.org>, Boqun Feng <boqun.feng@gmail.com>, 
 Miguel Ojeda <ojeda@kernel.org>, Alex Gaynor <alex.gaynor@gmail.com>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <benno.lossin@proton.me>, Alice Ryhl <aliceryhl@google.com>
Cc: Shuah Khan <skhan@linuxfoundation.org>, 
 Anup Sharma <anupnewsmail@gmail.com>, netdev@vger.kernel.org, 
 rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-block@vger.kernel.org, Manas <manas18244@iiitd.ac.in>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1731935537; l=1089;
 i=manas18244@iiitd.ac.in; s=20240813; h=from:subject:message-id;
 bh=mynh6sk8RoVgNyY4+tCv1gPC6C3Qaqxtwv1pM7qKGxI=;
 b=NIq7enWghtGJmPtwMxRPMx2hjBp6cdJYkvGzFhObjXO9HQlM1ll9+VlepGEXfM1RjQ3XekVqW
 34Qzlh1WHo3BzgxH9PeFxze6MJoRyqNIp0cdjdFJPyaTrBCmcuUX5e4
X-Developer-Key: i=manas18244@iiitd.ac.in; a=ed25519;
 pk=pXNEDKd3qTkQe9vsJtBGT9hrfOR7Dph1rfX5ig2AAoM=
X-Endpoint-Received: by B4 Relay for manas18244@iiitd.ac.in/20240813 with auth_id=196
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

`Result` is used in place of `Result<()>` because the default type
parameters are unit `()` and `Error` types, which are automatically
inferred. This patch keeps the usage consistent throughout codebase.

Signed-off-by: Manas <manas18244@iiitd.ac.in>
---
 rust/kernel/block/mq/gen_disk.rs | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/rust/kernel/block/mq/gen_disk.rs b/rust/kernel/block/mq/gen_disk.rs
index 708125dce96a934f32caab44d5e6cff14c4321a9..798c4ae0bdedd58221b5851a630c0e1052e0face 100644
--- a/rust/kernel/block/mq/gen_disk.rs
+++ b/rust/kernel/block/mq/gen_disk.rs
@@ -45,7 +45,7 @@ pub fn rotational(mut self, rotational: bool) -> Self {
 
     /// Validate block size by verifying that it is between 512 and `PAGE_SIZE`,
     /// and that it is a power of two.
-    fn validate_block_size(size: u32) -> Result<()> {
+    fn validate_block_size(size: u32) -> Result {
         if !(512..=bindings::PAGE_SIZE as u32).contains(&size) || !size.is_power_of_two() {
             Err(error::code::EINVAL)
         } else {

-- 
2.47.0

