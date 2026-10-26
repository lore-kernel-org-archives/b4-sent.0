From: Dave Airlie <airlied@redhat.com>
Date: Mon, 26 Oct 2026 12:56:48 +1000
Subject: [PATCH 1/2] rust/timer: expose as_nanos for clock sources.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261026-drm-rust-next-v1-1-14a4ae469175@redhat.com>
References: <20261026-drm-rust-next-v1-0-14a4ae469175@redhat.com>
In-Reply-To: <20261026-drm-rust-next-v1-0-14a4ae469175@redhat.com>
To: Andreas Hindborg <a.hindborg@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 FUJITA Tomonori <fujita.tomonori@gmail.com>, Lyude Paul <lyude@redhat.com>, 
 Gary Guo <gary@garyguo.net>, Danilo Krummrich <dakr@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>
Cc: rust-for-linux@vger.kernel.org, nova-gpu@lists.linux.dev, 
 Dave Airlie <airlied@redhat.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=728; i=airlied@redhat.com;
 h=from:subject:message-id; bh=FaDhVNX1ZRVIPh01nVKyHlUNaG65BCt2llMd3Ejbhi8=;
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBq3sF5ffu6oD8lkLuacynLoQPYjFNgwsV2/dErZ
 N1B6yWSwx+JAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCat7BeQAKCRAMdPNZecSG
 vvXKD/0Q7saaW3jlDG9yPONZZPG5DR8FZ2JihdC/yNTM/84Jp4yGr0+Qr5X7xA4M3Sj5ubF1qTW
 aHMQRw0kSM9X1RxbXUjhnJ61ydjL75px08kRuxAzGc//dUk3ABw6RXE38iZNZXav4rLJQ9tBrkx
 SjHmcYd53cMjry8EKtDkei9TIXZr6PS4S6X/oTlBr3HVy/GmND+5f4XujvPanx+3ptkFfxkzzNx
 R0zaXZyNFmabPwXTchL4kleByprmeCpdpAaicn3k05vZYdFynsJ7ieRLFBlw9RmwzxqpX21Q2PV
 ew+hyXfWsjPJy60yO1g27ehIoudf8pp+46EbaCUvURsLuTQ/otQgUjGjHd7ZiEHck+0X7vBjoSW
 jevcUvJ2sHvzEKZNaX55XOy+gja756rmMOkXKddozWKcejAGtfKXmaVZ91NMPJsPVV7tB29QiB/
 9tu7O8IdZnAZD1/VvoDa8kcAs2JA45P90gSo+6Knl/n40xWLP3NrUclhQhcM3pV47YGSZOCAfPJ
 9Hy/urfQ2E69s+YLmZhsubD054IzEL/2SJXuAC5jGBkTvP96pbOUQ01bQAASX9oi+JhdwFLoOBE
 9zQvxPqZxW+8bKW8n++vsR6Oc/kWQFhNlluWdhXhcTsWFSuztnl2spMooA2NJLk1uLP9aGx5Kp5
 I6OPwYhPK/PbmAQ==
X-Developer-Key: i=airlied@redhat.com; a=openpgp;
 fpr=10A6D91DA1B05BD29F6DEBAC0C74F35979C486BE
X-Endpoint-Received: by B4 Relay for airlied@redhat.com/default with auth_id=1321
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The nouveau C driver does ktime_to_ns(ktime_get()) to program
the cpu ns into some hw/fw, so allow this method for rust drivers.

Signed-off-by: Dave Airlie <airlied@redhat.com>
---
 rust/kernel/time.rs | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/rust/kernel/time.rs b/rust/kernel/time.rs
index 6c0a5e8090d0..7fc366842901 100644
--- a/rust/kernel/time.rs
+++ b/rust/kernel/time.rs
@@ -211,8 +211,9 @@ pub fn elapsed(&self) -> Delta {
         Self::now() - *self
     }
 
+    /// Return the raw nanonseconds values from the clock source.
     #[inline]
-    pub(crate) fn as_nanos(&self) -> i64 {
+    pub fn as_nanos(&self) -> i64 {
         self.inner
     }
 

-- 
2.56.0

