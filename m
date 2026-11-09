From: Dave Airlie <airlied@redhat.com>
Date: Mon, 09 Nov 2026 11:55:58 +1000
Subject: [PATCH v6 1/2] rust: time: expose as_nanos for clock sources.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-nova-timer-v6-1-5544a3bd8b28@redhat.com>
References: <20261109-nova-timer-v6-0-5544a3bd8b28@redhat.com>
In-Reply-To: <20261109-nova-timer-v6-0-5544a3bd8b28@redhat.com>
To: Andreas Hindborg <a.hindborg@kernel.org>, 
 FUJITA Tomonori <fujita.tomonori@gmail.com>, Gary Guo <gary@garyguo.net>, 
 Alice Ryhl <aliceryhl@google.com>, Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Alexandre Courbot <acourbot@nvidia.com>
Cc: nova-gpu@lists.linux.dev, dri-devel@lists.freedesktop.org, 
 Dave Airlie <airlied@redhat.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=890; i=airlied@redhat.com;
 h=from:subject:message-id; bh=3VDfb37tDtN07HLm+c2mhReutHmj5DLfx9YKQGaiDDc=;
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBq8Sg1nwJDFD0BwL7AahvaGXI2t3glOckQwM+Jd
 G7L6eePEQ6JAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCavEoNQAKCRAMdPNZecSG
 vomnD/41GUlSU79VunLNAVJgpObH6rSqjWEgOpIxgSFJtqoBJEWGBmLaqEDPlYupjFw1SNEltI/
 fyg+E9C/6utZrkXPB2jjePzMho8oGfCnMvVCrGWD+RTjmHirYAxlBTh6DFUo4vC3Bjv/oU+Djo5
 XnvZg90gjOlNNW3ClRJpzbDmxFRz5HXSP7Iqto1DjoGL0csuczfu9ny5VynOakrIbQKWsxPeIAK
 OT/Vbq/dGpvuMbtn1IE/QifvxCmAVSZPdHWUtxSy3AlVbgC8Dj+DoSCCdq6BHT/LnNgg7cTdENQ
 62pjE5dExCwU2N05PQWyb4r14hNvsaL+q82z+jwkBdEKXvMwvUZitX8JMbACc84gXiT41J7Os9l
 MLxG22bYcjiohEJy1EPj+WET+GyH7JYJarfBLwtXVFJAjGXFFRhqAX6dYPhKHPk01hylEnM1nGM
 7nmNyYJelB0ywy6iUhP2YNEIav4483TzHHW0hTUOBexWtPCoXdkvbAJkDI5hnU7NkNzn6bmxccU
 6VpVsRwse2jrg1ORoiCJ7b0sOda7Aww2pJNccrFWfdVI/aZVeI4eaeJGMkG6Q8hk71kmLPFxt7Q
 YG98iY+fcYve4rjU2CojT6c4bgZVZAK+QRhWeZiohmNzLEKHo/pPi1CMS5orDbzlGhZm7j6mV6M
 beRiS+SReIrcZFw==
X-Developer-Key: i=airlied@redhat.com; a=openpgp;
 fpr=10A6D91DA1B05BD29F6DEBAC0C74F35979C486BE
X-Endpoint-Received: by B4 Relay for airlied@redhat.com/default with auth_id=1321
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The nouveau C driver does ktime_to_ns(ktime_get()) to program
the cpu ns into some hw/fw, so allow this method for rust drivers.

This is needed for following nova patch.

Reviewed-by: FUJITA Tomonori <fujita.tomonori@gmail.com>
Reviewed-by: Alexandre Courbot <acourbot@nvidia.com>
Signed-off-by: Dave Airlie <airlied@redhat.com>
---
 rust/kernel/time.rs | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/rust/kernel/time.rs b/rust/kernel/time.rs
index b6a2aab12a50..4409291f3ffa 100644
--- a/rust/kernel/time.rs
+++ b/rust/kernel/time.rs
@@ -215,8 +215,9 @@ pub fn elapsed(&self) -> Delta {
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

