From: Peder Bergan <peder.bergan@gmail.com>
Date: Thu, 26 Nov 2026 17:53:17 +0100
Subject: [PATCH 3/3] drm/panic: Simplify QR error correction exponent
 reduction
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-perf-drm-panic-qr-v1-3-51856937dc4d@gmail.com>
References: <20261126-perf-drm-panic-qr-v1-0-51856937dc4d@gmail.com>
In-Reply-To: <20261126-perf-drm-panic-qr-v1-0-51856937dc4d@gmail.com>
To: Jocelyn Falempe <jfalempe@redhat.com>, 
 Javier Martinez Canillas <javierm@redhat.com>
Cc: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 dri-devel@lists.freedesktop.org, rust-for-linux@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795711998; l=1585;
 i=peder.bergan@gmail.com; s=kernel-contributions; h=from:subject:message-id;
 bh=jOYNOD5E6yoy7JZimrIqJExB0NGTGDoxm0GeT3zDnb4=;
 b=kva8hevRr4jLZgPXiXP32AbjpKIn0JmGDc+elnVXsnDOvTOQH9cnOU+iv4pyCxeUrnrBXQhzb
 DganHaRZQGeAtcg8bTINMuOIo4dDq6MrJIgNPkJViYolYbcqUMhTfb4
X-Developer-Key: i=peder.bergan@gmail.com; a=ed25519;
 pk=39790pn1YZCulHBoUG1uiQI1Hm01EvhBEa2zVrS/yN0=
X-Endpoint-Received: by B4 Relay for peder.bergan@gmail.com/kernel-contributions with auth_id=1395
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Reed-Solomon error correction reduces the sum of two GF(256) exponents
modulo 255 for each generator coefficient. Both exponents are below
255, so the sum needs at most one subtraction.

Use a conditional subtraction for the reduction. In the x86-64
userspace benchmark, this replaces a multiply-and-shift sequence with
a comparison and conditional moves. On top of the first two patches,
the change saved about 32 us per version-40 encode with raw input and
31 us with a URL.

Signed-off-by: Peder Bergan <peder.bergan@gmail.com>
---
 drivers/gpu/drm/drm_panic_helper_qr.rs | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/drm_panic_helper_qr.rs b/drivers/gpu/drm/drm_panic_helper_qr.rs
index 1d96ae855052a..4ba2e3de5a6b6 100644
--- a/drivers/gpu/drm/drm_panic_helper_qr.rs
+++ b/drivers/gpu/drm/drm_panic_helper_qr.rs
@@ -569,7 +569,10 @@ fn error_code_for_blocks(&mut self, offset: usize, size: usize, ec_offset: usize
             }
             let log_lead_coeff = usize::from(LOG_TABLE[lead_coeff]);
             for (u, &v) in tmp[i + 1..].iter_mut().zip(self.poly.iter()) {
-                *u ^= EXP_TABLE[(usize::from(v) + log_lead_coeff) % 255];
+                // Both exponents are below 255, so at most one subtraction is needed.
+                let sum = usize::from(v) + log_lead_coeff;
+                let index = if sum >= 255 { sum - 255 } else { sum };
+                *u ^= EXP_TABLE[index];
             }
         }
         self.data[ec_offset..ec_offset + self.ec_size]

-- 
2.56.1

