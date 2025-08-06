From: Cryolitia PukNgae <cryolitia@uniontech.com>
Date: Wed, 06 Aug 2025 11:34:18 +0800
Subject: [PATCH] drm/amdgpu: fix incorrect comment format
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250806-amdgpu_typo-v1-1-b5a3cb84ce26@uniontech.com>
X-B4-Tracking: v=1; b=H4sIADnNkmgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDCwMz3cTclPSC0viSyoJ8XQsDCzPLJEMjo2RjMyWgjoKi1LTMCrBp0bG
 1tQACdEg2XQAAAA==
X-Change-ID: 20250806-amdgpu_typo-80869b122c36
To: Alex Deucher <alexander.deucher@amd.com>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: amd-gfx@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, wangyuli@uniontech.com, zhanjun@uniontech.com, 
 guanwentao@uniontech.com, Cryolitia PukNgae <cryolitia@uniontech.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754451263; l=1198;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=k+gY44TRXxHS44Et5U7hyAbjjywRyysMNE2p/m6W2bk=;
 b=scrrcR+qucYdJOb23SqbCcLG/aPsSIlZavZRQjljyvWN3luE7E0YF0hYRvtsZC7q8Fb2wsGPL
 6J7+X73na1/CqDc0X1MznKWPaBxmB5oEOA62tx24u1QQCfiWEe5UnBy
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Comments should not have a leading plus sign.

Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
---
 drivers/gpu/drm/amd/amdgpu/nbio_v7_4.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/drivers/gpu/drm/amd/amdgpu/nbio_v7_4.c b/drivers/gpu/drm/amd/amdgpu/nbio_v7_4.c
index d5002ff931d841994ca2c70cdf5b989f5b3c59d6..860bc5cb03c81b5346743b5fb46a7dcbe5a201a4 100644
--- a/drivers/gpu/drm/amd/amdgpu/nbio_v7_4.c
+++ b/drivers/gpu/drm/amd/amdgpu/nbio_v7_4.c
@@ -151,9 +151,9 @@ static void nbio_v7_4_sdma_doorbell_range(struct amdgpu_device *adev, int instan
 		 *   BIF_SDMA0_DOORBELL_RANGE:  0x3bc0
 		 *   BIF_SDMA1_DOORBELL_RANGE:  0x3bc4
 		 *   BIF_SDMA2_DOORBELL_RANGE:  0x3bd8
-+		 *   BIF_SDMA4_DOORBELL_RANGE:
-+		 *     ARCTURUS:  0x3be0
-+		 *     ALDEBARAN: 0x3be4
+		 *   BIF_SDMA4_DOORBELL_RANGE:
+		 *     ARCTURUS:  0x3be0
+		 *     ALDEBARAN: 0x3be4
 		 */
 		if (adev->asic_type == CHIP_ALDEBARAN && instance == 4)
 			reg = instance + 0x4 + 0x1 +

---
base-commit: 6bcdbd62bd56e6d7383f9e06d9d148935b3c9b73
change-id: 20250806-amdgpu_typo-80869b122c36

Best regards,
-- 
Cryolitia PukNgae <cryolitia@uniontech.com>

