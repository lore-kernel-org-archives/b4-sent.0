From: Dave Airlie <airlied@redhat.com>
Date: Mon, 02 Nov 2026 17:17:40 +1000
Subject: [PATCH 1/2] rust: time: expose as_nanos for clock sources.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261102-nova-timer-v1-1-b347ead64469@redhat.com>
References: <20261102-nova-timer-v1-0-b347ead64469@redhat.com>
In-Reply-To: <20261102-nova-timer-v1-0-b347ead64469@redhat.com>
To: Andreas Hindborg <a.hindborg@kernel.org>, 
 FUJITA Tomonori <fujita.tomonori@gmail.com>, Gary Guo <gary@garyguo.net>, 
 Alice Ryhl <aliceryhl@google.com>, Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Alexandre Courbot <acourbot@nvidia.com>
Cc: nova-gpu@lists.linux.dev, dri-devel@lists.freedesktop.org, 
 Dave Airlie <airlied@redhat.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=792; i=airlied@redhat.com;
 h=from:subject:message-id; bh=pY3ItZTyRBqrXe1s0swCsV4mLrXTPTHBAc2wQUfEkfs=;
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBq6Dkd4edhhC5d0PBanFuqdPfSRLxn9C0KZMcmq
 R6QvApbHsmJAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCaug5HQAKCRAMdPNZecSG
 vknnD/9PIRPEaWJ4iBZf/3M0f+Df4OQr8YuCkj7JIwVU2Hnp7HUgZpT96c4YCpNG6vX4IETenYO
 /f0MDQ/so5SHJBFdgge3192sTNTBNcWp6NrHOneIJQ7aVVTlV1uapVKyYkL0PkPKzr9xyvYyy6y
 v1GMlXiEf0z9s60gkdAO6hCUwGTQ5RlpAQE0NnuK6eI6L6jGuSXSIkCKyNhqrSdg2/UQA/szels
 44vV3DRWgbqrrCZyLigaolG7ytwHiT12K48tjrvr7je+qENQwIXBUXQEdqm3+WhCzVCLfzEaMUZ
 cKZXirLWKD16DkvpVbT38zT6lwqC3ptd1lbdcgWff64glQc96qtUZ82YOW1mm6Ji5g3sFqFzUlY
 DOClNG3bZ504qiPe6ZS3upbhtlFz1W/XV6RN0OO4upppvN2RpAWDqAhMDN7gt70iDhcKTHg2QIB
 UM7N0Zb0AjyB/FXvk0sdTrE1QVkFcTaufQX02l7EJb/ifx+Gtzu/UPDsCivHq0fQ9IdXeQuoJG2
 rx6O1Ubz8zrAQD7TXXkg/hd4gUhZywL8FxxYRpFpt5nLxbkb0cjeljOOSdImu+hq/yw0QgSquUp
 5WOvQUrEJ2jJ5A6JKvpTZLST0YrQnx2CCZ5w09+j/wvEEajk4RM9FD3KHMFQoUIIbstIBJ8B1+1
 J7Bqp1pdkqV/lww==
X-Developer-Key: i=airlied@redhat.com; a=openpgp;
 fpr=10A6D91DA1B05BD29F6DEBAC0C74F35979C486BE
X-Endpoint-Received: by B4 Relay for airlied@redhat.com/default with auth_id=1321
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The nouveau C driver does ktime_to_ns(ktime_get()) to program
the cpu ns into some hw/fw, so allow this method for rust drivers.

Reviewed-by: FUJITA Tomonori <fujita.tomonori@gmail.com>
Signed-off-by: Dave Airlie <airlied@redhat.com>
---
 rust/kernel/time.rs | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/rust/kernel/time.rs b/rust/kernel/time.rs
index 6c0a5e8090d0..a91ddf04785b 100644
--- a/rust/kernel/time.rs
+++ b/rust/kernel/time.rs
@@ -211,8 +211,9 @@ pub fn elapsed(&self) -> Delta {
         Self::now() - *self
     }
 
+    /// Return the raw nanoseconds values since the epoch of clock `C`.
     #[inline]
-    pub(crate) fn as_nanos(&self) -> i64 {
+    pub fn as_nanos(&self) -> i64 {
         self.inner
     }
 

-- 
2.56.0

