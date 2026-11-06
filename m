From: Dave Airlie <airlied@redhat.com>
Date: Fri, 06 Nov 2026 15:34:02 +1000
Subject: [PATCH v5 1/2] rust: time: expose as_nanos for clock sources.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-nova-timer-v5-1-a0cd25f3ee18@redhat.com>
References: <20261106-nova-timer-v5-0-a0cd25f3ee18@redhat.com>
In-Reply-To: <20261106-nova-timer-v5-0-a0cd25f3ee18@redhat.com>
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
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBq7WbQKS4Byme7iSfrmcFJBVcSx/qvq/fFrwEdw
 R4AKKwkXRSJAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCau1m0AAKCRAMdPNZecSG
 vpUEEAChtkOLcH2fwPeHNgCHf25MY9QXYKZHB4rkgMxJHcRcoom0bUrHX5wRbdTSXPrD92jQ53u
 xlHIDe5kE8MhPADu9T05lira3CJyGnr3ofGVVHEzM+LIMYViXV07xEQAjwPBrgDhpa+qDdG94sa
 /DQnUeSxu3ohXZeEvOVuxR09SWRdrth95sxxX0OkRSY09x4iUHIbrdxW5QEFr8jIuszBeLGwYpr
 sG6YI3602ztC/UKGpgsiD6L5XT4phrLgp7ZWjSfZNGjNrrtGOEauGcMgDp8a74f6ILcatmK5cyb
 Fx1zvNSjL8dvH+uOKIqhLxZf/0Qs3y5luxiOCspkzM4kE4vC3iYvVU9rvcKiiYEElfLZbWCImbZ
 GiLH7Eg+ygPxb1qpcfqOBy70tLVdnwfhPvYbCR4/hKFEcg1AZvbu0O+rH8tqQmZM8aLfWR8CNiz
 m2LYTZM1VE5L7+0gTM4OblzZJscKU+0QxEfNbXBoa7BV1lEXvDLmXCB+ufrp1MrtnqzrjHfHGzx
 HmWxHtNg2LzLAgyBjTay92dQhkAMtW892f/0pe3b4oVQ4rGxfrj2DysT42eIvUthP6VMDgKlJkp
 iQoqcHrVgwS1Oh8QxrDXPvfFNbgtrSHT9sfiuUv30XJrmpHSwNbwVC+CSQj3/5fYpv7VEVc8cgA
 nYlgJjvzH6ol7DQ==
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

