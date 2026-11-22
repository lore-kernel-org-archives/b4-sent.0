From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Date: Mon, 23 Nov 2026 00:50:03 +0530
Subject: [PATCH v2] interconnect: qcom: Don't read back BCMs without an
 RPMh address
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-icc-bcm-readback-v2-1-b470ed2bb7f4@yahoo.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NQQ6CMBBFr0Jm7RhKYyOuvIdhMR0GGQ3UtEgkh
 LsLuHf5kvffnyFJVElwyWaIMmrS0K9QHDLglvq7oNYrQ5EXzhjjUJnRc4dRqPbETyRry+bMJD4
 vYZ29ojT62ZO36sfp7R/Cw9bZjFbTEOK0f45m8/7kR4MGrfMna2vnyJXXidoQjhw6qJZl+QLht
 Z8swgAAAA==
X-Change-ID: 20261116-icc-bcm-readback-a339f8caeb09
To: Georgi Djakov <djakov@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Abel Vesa <abel.vesa@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, linux-pm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Venkat Yadlapati <venkat.yadlapati@yahoo.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795375202; l=2810;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=+1XaK5OK8j/KqvYoTiFyF9kYItUTNV/Y3VVPDk052A4=;
 b=n0m9CWqAcfG/LxNDiu+/+IqZPLT28lKYhcwsmXO2JDyFy5obl3FLAoT5Fjg+ildCVVHuEDDOh
 LcofgTwovyJARTpLU6boX2FS9vmvuCApH4CYdazVSaIe0w651N9iJnu
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

qcom_icc_rpmh_probe() ignores the return value of qcom_icc_bcm_init()
and reads the initial vote of every BCM back with rpmh_read(). When the
command DB has no entry for a BCM, qcom_icc_bcm_init() fails before
setting the address, so the read goes to RPMh address 0. On Molokai
(SM8845), whose command DB lacks the QPC0 BCM of the Kaanapali gem_noc,
that read never completes and every later RPMh request times out, so the
regulators fail to probe and the boot stalls:

  qnoc-kaanapali 31100000.interconnect: QPC0 could not find RPMh address
  qcom-rpmh-regulator 18900000.rsc:regulators-2: failed to read ENABLE status ret = -110
  Error sending AMC RPMH requests (-110)

Skip the read back for a BCM that failed to initialize, like before the
read back was added, when such a BCM was simply never voted.

Fixes: 11a44c6087c6 ("interconnect: qcom: implement get_bw with rpmh_read")
Reviewed-by: Neil Armstrong <neil.armstrong@linaro.org>
Signed-off-by: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
---
Found while bringing up the Motorola Signature (Qualcomm Molokai, SM8845)
on next-20261113: the boot stalled in the regulator probe and every RPMh
request timed out after the first one. The Molokai command DB has no QPC0
entry, so qcom_icc_bcm_init() fails for it, and the read back added in
commit 11a44c6087c6 then reads RPMh address 0, which never completes.

Tested on the Motorola Signature: no RPMh timeouts, the regulators and
the interconnect providers probe, and the rest of the boot is unchanged.

I used an LLM (Claude) to help write this patch and its commit message.
I reviewed it and tested the result on the device.
---
Changes in v2:
- Drop the Assisted-by trailers and the LLM notes from the commit
  messages, the LLM use is stated in this cover letter.
- Pick up the Reviewed-by of Neil.
- Link to v1: https://patch.msgid.link/20261116-icc-bcm-readback-v1-1-36b533d66a69@yahoo.com
---
 drivers/interconnect/qcom/icc-rpmh.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/drivers/interconnect/qcom/icc-rpmh.c b/drivers/interconnect/qcom/icc-rpmh.c
index 4a2a746a4e59..1fbf4c960e1e 100644
--- a/drivers/interconnect/qcom/icc-rpmh.c
+++ b/drivers/interconnect/qcom/icc-rpmh.c
@@ -332,7 +332,9 @@ int qcom_icc_rpmh_probe(struct platform_device *pdev)
 		return PTR_ERR(qp->voter);
 
 	for (i = 0; i < qp->num_bcms; i++) {
-		qcom_icc_bcm_init(qp->bcms[i], dev);
+		/* Don't read back a BCM without an RPMh address */
+		if (qcom_icc_bcm_init(qp->bcms[i], dev))
+			continue;
 		qcom_icc_bcm_get_bw(qp->voter, qp->bcms[i]);
 	}
 

---
base-commit: 3fd56a2833c22f62eb84297d0dbd47739632f1a0
change-id: 20261116-icc-bcm-readback-a339f8caeb09

Best regards,
--  
Venkat Yadlapati <venkat.yadlapati@yahoo.com>

