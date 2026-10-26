From: Filippo Falezza <effeffe99@gmail.com>
Date: Mon, 26 Oct 2026 18:19:07 +0000
Subject: [PATCH] remoteproc: qcom: pas: Print auth error code
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261026-pas-auth-error-v1-1-1569e83358e5@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQqDMBCE4VeRPbuQiBTaVykeYhyb7SHKroogv
 ntTPczhO8x/kEEFRq/qIMUmJlMu8HVFMYX8ActQTI1rHr6M52Ac1iUxVCdltLF9un7w0YHKaVa
 Msl/Bd3fb1v6LuPwrdJ4/s+C2enIAAAA=
X-Change-ID: 20261026-pas-auth-error-e4c490bd1c0e
To: Bjorn Andersson <andersson@kernel.org>, 
 Mathieu Poirier <mathieu.poirier@linaro.org>
Cc: linux-arm-msm@vger.kernel.org, linux-remoteproc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Filippo Falezza <effeffe99@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793038746; l=2798;
 i=effeffe99@gmail.com; s=20261022; h=from:subject:message-id;
 bh=+UAPMP0mpA/2AP1Feq4iEAd04j9ngTHwcofPyCUE/Rw=;
 b=/A113p09qt5dybuOuaIFcfMOHoKqEPwur5s2OMpFXC4z7zJipTjl/hbYB7nEIOxAIUAuYW7Yh
 LamNBz+gD6bAmKVdj1qtMzrew4KsdCHGMtU6w61Kx9mlSpAZyYEyV+u
X-Developer-Key: i=effeffe99@gmail.com; a=ed25519;
 pk=7PPwl4QILojrh+ATB5QOpvXVmmoxaxyLQhrLRLWEL0I=
X-Endpoint-Received: by B4 Relay for effeffe99@gmail.com/20261022 with auth_id=1327
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a subsystem fails to start, qcom_pas_start() logs "failed to
authenticate image and release reset", but drops the error returned by
qcom_pas_prepare_and_auth_reset(). That code tells the failures apart:
a negative errno is either a clock, interconnect or SHM bridge failure
on the Linux side or the SCM call's own status, remapped by
qcom_scm_call(); a positive value is the status the PIL service
returned for the request. Without it, finding out which one happened
means adding a print and rebuilding the kernel.

Print the error code, for the DTB image as well as the main one.

Signed-off-by: Filippo Falezza <effeffe99@gmail.com>
---
Hello there,

this is a small one: when a remote processor fails to authenticate,
qcom_pas_start() says so but drops the error code, and that code is
what tells a TrustZone refusal apart from a problem on the Linux side.
The patch adds it to both messages, the main image and the DTB one.

I ran into this bringing up the Motorola Moto G 5G Plus (nairo,
SM7250), where the compute DSP will not start. With the patch it
reports "failed to authenticate image and release reset: -22", which
pointed at TrustZone refusing the call rather than at the image. The
ADSP and the modem still start as before. I could not test the DTB
path, as SM7250 has no DTB images.

It builds without warnings with W=1 (arm64 defconfig), checkpatch
--strict is clean, and it applies to rproc-next (82d0bbd67c42). The
change and the changelog were written with Claude Opus 5.5 in Claude
Code during that bring-up; I tested it on the phone and reviewed it
before sending.

Thanks,
Filippo
---
 drivers/remoteproc/qcom_q6v5_pas.c | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/drivers/remoteproc/qcom_q6v5_pas.c b/drivers/remoteproc/qcom_q6v5_pas.c
index abc59c0c29f0..ea3eb8e293c2 100644
--- a/drivers/remoteproc/qcom_q6v5_pas.c
+++ b/drivers/remoteproc/qcom_q6v5_pas.c
@@ -346,7 +346,8 @@ static int qcom_pas_start(struct rproc *rproc)
 		ret = qcom_pas_prepare_and_auth_reset(pas->dtb_pas_ctx);
 		if (ret) {
 			dev_err(pas->dev,
-				"failed to authenticate dtb image and release reset\n");
+				"failed to authenticate dtb image and release reset: %d\n",
+				ret);
 			goto unmap_dtb_carveout;
 		}
 	}
@@ -365,7 +366,7 @@ static int qcom_pas_start(struct rproc *rproc)
 	ret = qcom_pas_prepare_and_auth_reset(pas->pas_ctx);
 	if (ret) {
 		dev_err(pas->dev,
-			"failed to authenticate image and release reset\n");
+			"failed to authenticate image and release reset: %d\n", ret);
 		goto unmap_carveout;
 	}
 

---
base-commit: 82d0bbd67c42a44f0e18b0b7b0da0f3ace0c9527
change-id: 20261026-pas-auth-error-e4c490bd1c0e

Best regards,
--  
Filippo Falezza <effeffe99@gmail.com>

