From: Ishu Brar <patches@brar.si>
Date: Tue, 27 Oct 2026 12:44:38 +0530
Subject: [PATCH v4 5/5] drm/msm/a6xx: Protect the 0x1c800-0x1e7ff GMU range
 on A620 and A650
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-adreno-a620-v4-5-b0095e028c76@brar.si>
References: <20261027-adreno-a620-v4-0-b0095e028c76@brar.si>
In-Reply-To: <20261027-adreno-a620-v4-0-b0095e028c76@brar.si>
To: Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, Sean Paul <sean@poorly.run>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Konrad Dybcio <konradybcio@kernel.org>, 
 Akhil P Oommen <akhilpo@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, Ishu Brar <patches@brar.si>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793085280; l=1823;
 i=patches@brar.si; h=from:subject:message-id;
 bh=uJTDKKOJDAvrd0WSzrpyyryyzrwcJ4u+PPWaRGHdnNY=;
 b=RcTOxjE8hhv0TGlBtQlkofh7TIPAqZnkl+CNmTWxi5zzD41biNM8KTI3r5WnPAN4CLoM6BcXM
 O2YShEc11EMAt9Rp7hIYhKRsIiTFZuI8E5/8GkKmDBH1DLPHiE8fdS5
X-Developer-Key: i=patches@brar.si; a=ed25519;
 pk=Ds+E23E3ntzjPzuBDyVRkOouclcNI5k75R+N42yJtCk=
X-Endpoint-Received: by B4 Relay for patches@brar.si/default with auth_id=1189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

No protect entry covers the range from 0x1c800 to 0x1e7ff: the entry
at 0x1a800 ends at 0x1c7ff and the next one starts at 0x1f400. The range
holds GMU registers, among them GMU_NMI_CONTROL_STATUS (0x1cbf0),
GMU_BOOT_SLUMBER_OPTION (0x1cbf8), the GX and MX vote indexes (0x1cbf9,
0x1cbfa), the DCVS option, setting and return registers (0x1cbfc to
0x1cbff) and GMU_CORE_FW_VERSION (0x1d3f8), see a6xx_gmu.xml.

Add the range as no read/write to the A650 protect list, which A620 and
A650 share, so that these registers are reserved as well. This follows
Konrad Dybcio's suggestion; the downstream kgsl protect table of the
OnePlus Nord (a620_protected_regs) has no entry for this range, so there
is no downstream reference for it.

The list is also used by A621, A623, A702 and A704, which I could not
test. Tested on A620 only (OnePlus Nord, a 7.3 based tree): a Vulkan
workload ran across GPU frequency changes without protect, fault or GMU
errors. A write into the range being rejected was not tested.

Suggested-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: Ishu Brar <patches@brar.si>
---
 drivers/gpu/drm/msm/adreno/a6xx_catalog.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/gpu/drm/msm/adreno/a6xx_catalog.c b/drivers/gpu/drm/msm/adreno/a6xx_catalog.c
index 6cdc3f5a2583..c93de04bb187 100644
--- a/drivers/gpu/drm/msm/adreno/a6xx_catalog.c
+++ b/drivers/gpu/drm/msm/adreno/a6xx_catalog.c
@@ -576,6 +576,7 @@ static const u32 a650_protect_regs[] = {
 	A6XX_PROTECT_RDONLY(0x0fc00, 0x1fff),
 	A6XX_PROTECT_NORDWR(0x18400, 0x1fff),
 	A6XX_PROTECT_NORDWR(0x1a800, 0x1fff),
+	A6XX_PROTECT_NORDWR(0x1c800, 0x1fff),
 	A6XX_PROTECT_NORDWR(0x1f400, 0x0443),
 	A6XX_PROTECT_RDONLY(0x1f844, 0x007b),
 	A6XX_PROTECT_NORDWR(0x1f887, 0x001b),

-- 
2.56.0

