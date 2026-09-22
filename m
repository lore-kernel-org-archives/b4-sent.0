From: David Heidelberg <david@ixit.cz>
Date: Wed, 23 Sep 2026 00:38:35 +0200
Subject: [PATCH] misc: fastrpc: Don't fail probe when the SDSP memory
 assign fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260923-fastrpc-fail-slow-v1-1-f3f6fabba6e3@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMSw5AQBBF0a1IjXVC+wRbEQNKoUSQrvZJxN41R
 i9n8O4FQoZJoPAuMLSz8DI7hL4HONRzT4pbZ9CBToNcR6qrxZoV3fKkZFoOFbeYRTmGaZYguN9
 qqOPza5bVb9makdC+IbjvB2r/TIt1AAAA
X-Change-ID: 20260923-fastrpc-fail-slow-4dc839c1685c
To: Srinivas Kandagatla <srini@kernel.org>, 
 Ekansh Gupta <ekansh.gupta@oss.qualcomm.com>, Arnd Bergmann <arnd@arndb.de>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Xingjing Deng <micro6947@gmail.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 stable@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2927; i=david@ixit.cz;
 h=from:subject:message-id; bh=LVflJZ/2wlziXXcgkjmUlvyrIA4JxMm8+0Fb6m1yJ2E=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqswN4Ww4Isn3b4+WGISIldgE1WYUqWK/0/8UBi
 M1hUa64M8eJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCarMDeAAKCRBgAj/E00kg
 cp2GD/9xpT04KcafxxzzzuuUOJgWk8Dnw017e+ML+4eNZ+x96udDkrJ26VRQ1lqKDPFSdP42hvq
 DgNVELWCJuJJ5l3F3vTfxDCzCicDK9d6lTYEw4RKO0UNgcXIEWxGadAAlmBZZT1V0P06eSCCqSE
 YqqIgcAduy0/GxU4M+cxUrmQ0TWf1eSPT2pTdEwCod6NqoDQ0D5vEWzfro8lAsunNTwDmgMwknO
 S8K+CDjufT1hgQy0ivffOW9IttgJy7Y5kdmuInnuJFZxQoxdYvuh7wzBFTfPXMOZYDyHG7xwO6U
 cdcaqYCqvsnLhpLiNps6PeX2Vgcz1ViuTxKLC868vOpikeML6yZPMnaJVd+rOnsTm55S+101J8x
 umLUQCiVFMhdOL9Pr0dQlOmAP9h9ML3/BaMuiR6CXsneIX4OYPhdggHikBRfGDqNXrbWIawmab2
 nQxixDbyzWBYEcbngxE5XVGSSD5s6P14hiiAwModMGE5ZDfyTa4gZwf4J1T7G2xS6tLvYDFN6IC
 nPj+e4wvyJVFFgRdf9HhuH6QqdTnvutEKoaUfO0iZkDi+kfvpVaLoxqqY2FQ7X8H5IuPKy3JF1I
 hp8JnhKU0rnCifDri+E9poYZhSRLKZP+EuQwp8DI9kuoKadNnsKMxeDlORXdgBcvudyqej0k+MV
 N3R0Vi7dj8ywbOA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A failed qcom_scm_assign_mem() aborts fastrpc_rpmsg_probe(). On SDM845 this
turns every SLPI subsystem restart into an endless probe failure loop:

 remoteproc3: crash detected in slpi: type fatal error
 remoteproc3: remote processor slpi is now up
 qcom_scm firmware:scm: Assign memory protection call failed -22
 qcom,fastrpc 5c00000.remoteproc:glink-edge.fastrpcglink-apps-dsp.-1.-1: probe with driver qcom,fastrpc failed with error -22
 qcom,fastrpc 5c00000.remoteproc:glink-edge.fastrpcglink-apps-dsp.-1.-1: rpmsg_dev_probe: failed: -22

The first assign succeeds and hands the reserved region to the VMIDs
described in qcom,vmids. qcom_scm_assign_mem() reports the resulting
owner set back through @srcvm, but the driver discards it, and nothing
reverses the assignment in fastrpc_rpmsg_remove(). When the glink
channel is re-announced after a subsystem restart, probe passes
src_perms = BIT(QCOM_SCM_VMID_HLOS) again, which no longer describes the
region, and the firmware rejects the call with -EINVAL.

At that point the region is already assigned, and HLOS is part of the
destination VMID list, so both the host and the DSP keep access. Failing
the probe only removes /dev/fastrpc-sdsp and makes the remote reopen the
channel, repeating the cycle indefinitely. Warn and continue instead

Assisted-by: LLM
Cc: stable@vger.kernel.org
Fixes: 6a502776f4a4 ("misc: fastrpc: check qcom_scm_assign_mem() return in rpmsg_probe")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
Tracking the current owner set so the re-assign is issued with the
correct source VMIDs is a separate fix, but I assume it would make sense
to keep that to someone with more knowledge of fastrpc.

I aim here to reverting into usable state again which can be also
backported.

Tested on Pixel 3 and 3 XL.
---
 drivers/misc/fastrpc.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/drivers/misc/fastrpc.c b/drivers/misc/fastrpc.c
index 90fd669636ec1..41943a3d496af 100644
--- a/drivers/misc/fastrpc.c
+++ b/drivers/misc/fastrpc.c
@@ -2590,17 +2590,19 @@ static int fastrpc_rpmsg_probe(struct rpmsg_device *rpdev)
 
 		err = of_reserved_mem_region_to_resource(rdev->of_node, 0, &res);
 		if (!err) {
 			src_perms = BIT(QCOM_SCM_VMID_HLOS);
 
 			err = qcom_scm_assign_mem(res.start, resource_size(&res), &src_perms,
 				    data->vmperms, data->vmcount);
 			if (err)
-				goto err_free_data;
+				dev_warn(rdev,
+					 "assign memory to SDSP failed: %d\n",
+					 err);
 		}
 
 	}
 
 	secure_dsp = !(of_property_read_bool(rdev->of_node, "qcom,non-secure-domain"));
 	data->secure = secure_dsp;
 	data->soc_data = soc_data;
 	data->poll_mode_supported = soc_data->poll_mode_supported ||

---
base-commit: 7079a12d7506b07fb53b54a664bfad5fa9b16d70
change-id: 20260923-fastrpc-fail-slow-4dc839c1685c

Best regards,
--  
David Heidelberg <david@ixit.cz>

