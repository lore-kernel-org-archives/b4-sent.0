From: Ekansh Gupta <ekansh.gupta@oss.qualcomm.com>
Date: Tue, 19 May 2026 11:45:51 +0530
Subject: [PATCH 01/15] MAINTAINERS: Add entry for Qualcomm DSP Accelerator
 (QDA) driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260519-qda-series-v1-1-b2d984c297f8@oss.qualcomm.com>
References: <20260519-qda-series-v1-0-b2d984c297f8@oss.qualcomm.com>
In-Reply-To: <20260519-qda-series-v1-0-b2d984c297f8@oss.qualcomm.com>
To: Oded Gabbay <ogabbay@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, Joerg Roedel <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Sumit Semwal <sumit.semwal@linaro.org>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>
Cc: Bharath Kumar <quic_bkumar@quicinc.com>, 
 Chenna Kesava Raju <quic_chennak@quicinc.com>, srini@kernel.org, 
 dmitry.baryshkov@oss.qualcomm.com, andersson@kernel.org, 
 konradybcio@kernel.org, robin.clark@oss.qualcomm.com, 
 linux-kernel@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 linux-doc@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 iommu@lists.linux.dev, linux-media@vger.kernel.org, 
 linaro-mm-sig@lists.linaro.org, 
 Ekansh Gupta <ekansh.gupta@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779171352; l=1114;
 i=ekansh.gupta@oss.qualcomm.com; s=20260223; h=from:subject:message-id;
 bh=AcTCOc39xB2eWZrt+ASexMe8l7bzMXO4brOtNDdJpLc=;
 b=XwNsf2StpfGEc03MIN5ksLv66Pg0T/usYVgQPmqfzw5MxB6jXvhJsbXX7bTYyLF5Fy7wEzC3K
 d5yJ5e27faWDfrCTzW5xSeogxKwAaQNBtjHjh56ZsIQNBZP6cslu86G
X-Developer-Key: i=ekansh.gupta@oss.qualcomm.com; a=ed25519;
 pk=n0SepARizye+pYjhjg1RA5J+Nq4+IJbyRcBybU+/ERQ=
X-Endpoint-Received: by B4 Relay for ekansh.gupta@oss.qualcomm.com/20260223 with auth_id=647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a MAINTAINERS entry for the Qualcomm DSP Accelerator (QDA) driver,
covering the driver source under drivers/accel/qda, documentation under
Documentation/accel/qda, and the UAPI header
include/uapi/drm/qda_accel.h. The linux-arm-msm and dri-devel mailing
lists are listed as the relevant review lists.

Assisted-by: Claude:claude-4-6-sonnet
Signed-off-by: Ekansh Gupta <ekansh.gupta@oss.qualcomm.com>
---
 MAINTAINERS | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 3dd58a16f06a..c5c13ad1e6fe 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -22083,6 +22083,15 @@ S:	Maintained
 F:	Documentation/devicetree/bindings/crypto/qcom-qce.yaml
 F:	drivers/crypto/qce/
 
+QUALCOMM DSP ACCELERATOR (QDA) DRIVER
+M:	Ekansh Gupta <ekansh.gupta@oss.qualcomm.com>
+L:	linux-arm-msm@vger.kernel.org
+L:	dri-devel@lists.freedesktop.org
+S:	Supported
+F:	Documentation/accel/qda/
+F:	drivers/accel/qda/
+F:	include/uapi/drm/qda_accel.h
+
 QUALCOMM EMAC GIGABIT ETHERNET DRIVER
 M:	Timur Tabi <timur@kernel.org>
 L:	netdev@vger.kernel.org

-- 
2.34.1

