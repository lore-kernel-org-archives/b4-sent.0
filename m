From: Dave Airlie <airlied@redhat.com>
Date: Thu, 05 Nov 2026 13:07:01 +1000
Subject: [PATCH v4 1/2] rust: time: expose as_nanos for clock sources.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-nova-timer-v4-1-45a7c121d4de@redhat.com>
References: <20261105-nova-timer-v4-0-45a7c121d4de@redhat.com>
In-Reply-To: <20261105-nova-timer-v4-0-45a7c121d4de@redhat.com>
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
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBq6/LinQrRIgnADixMz/1LLvcnvKze93v1m29UU
 9BSMfoqMfeJAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCauvy4gAKCRAMdPNZecSG
 voJWD/9iI9cHbRPA2S7bph6eVyjExg8j3Ez7Gt40uUXd0VSd9I7SYYQFGAJ6xmgQaupBnTrsHk0
 5C7FN9rJ9+ywLimVIK6nIwltSkMpWt5rJUGETgIdrulR+V4oaSkyjCpwFQyV/hxzD2hiy3Hj8oW
 /E5QWRrGb+ipQhrWN3qNRHRu/VnAlxIwY/v9+0+feDGIixcS6Ao1jU1vmA1cvt0n4A/ff+8NcvI
 CAkSX/HTLXlctRMXhrYrQBG224bJhc8Ngt1hoA3BvdBZEpEPQtKOkR4gLaQu1FK3v9/wD/vdPmZ
 6PF4OL9yHyl5rbyHeWV3shW4DsLngS5bzXbQNQpHaVgbm9RPipJ7x31eGzSMrJCUJuD4eJWgvgF
 k4MVDGZmS5yDY3Dl/VjB/8DJhhIdQIMLuDzIxtbznhZ+/6nXbcvyDhnvJjP8UjbEiOdDZoMoi6W
 WRO5VUQxjTCmO4xz0jswRt4q7HPiGUu05z1+p1ObJ0vk34bRvmv9DdCYnDywjclcBGjERcwtkHs
 umONmwpSX20FnsbPfG5fjrh3rwOytgvQrWoKjxdQyB5ElKDD38R7XFCXqqtYncBpeYERl9VSFjT
 EuB+x5p5xBLEl2SwuYKDWZGIrOc4UOAXOqrA9zc+kPnvrg0YTb9e9yAOixIHBU7EaDo6II2vfFM
 bAQJFlwBhVuSCCw==
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

