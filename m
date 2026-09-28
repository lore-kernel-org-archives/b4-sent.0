From: David Heidelberg <david@ixit.cz>
Date: Mon, 28 Sep 2026 23:42:39 +0200
Subject: [PATCH] media: venus: core: look up static codec nodes among
 children only
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260928-venus-of-node-ref-v1-1-7579fb84445a@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMywqEMAyF4VeRrCegUby9yuBCazrGRSuNiiC+u
 9VZfgfOf4JyEFZokxMC76LiXUT2ScBMvfsxyhgNlFKZNlTjzm5T9BadHxkDWxzKpirI2p5MDvG
 3xFGOt/nt/tZtmNmsTwiu6wZ1+qSNdQAAAA==
X-Change-ID: 20260928-venus-of-node-ref-b69742ffa2c3
To: Vikash Garodia <vikash.garodia@oss.qualcomm.com>, 
 Dikshita Agarwal <dikshita.agarwal@oss.qualcomm.com>, 
 Bryan O'Donoghue <bod@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Stanimir Varbanov <stanimir.k.varbanov@gmail.com>, 
 Hans Verkuil <hverkuil@kernel.org>, Dan Carpenter <error27@gmail.com>
Cc: Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2898; i=david@ixit.cz;
 h=from:subject:message-id; bh=RcEQpaG3qjApty1CwkPYZ1bGIKgYZo3g8YmCYVk3/4g=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqut9PZoi6wYMcLOhfMI1e5kaNX46iKGzyTx1nP
 /n41g8T/veJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCarrfTwAKCRBgAj/E00kg
 cpIfD/9JrB03HWtW4Pd/RAJ2kwg5SKWnrlnqaHQI0mzpYp1J5FWrh+/c2hXbsgOVsdErI/zBmhL
 hhYx4dpZ6wzxj2bHf7w/1NxxCoYavZL2ghxwFT9Qpo6b9qCA0uwARacGTn2Lx9qzEthgnc07I3m
 5MGKYnZp9zDvTlWFf3tN6WtPrNkOoPoAQonOdcI3SsBPvOMq+Qlj6Sj3chZCG/pu436lbwSKGiV
 e1Bc9VVxEJd/FJDz1C4SsLWDvod4EKgb98nz9HAaFvBwdP+cMDjQv1tUxMl7+nzqvqZP4mjqDCX
 2nk3iKR4BQFX0PwDZlEAtC5nu3GLWoPlZLFNDCetVxsIA1z/DkRVxgeHxLNa3vxs2/H+s6bv9G7
 7aM3ziOiBt/OaC55UW+SaA5qluyvbkMOW46q02GebeCZGNrDpuuGl+ph2l5F66XzBEqihyXynyT
 2t4zIU8jRg4QT9OpTNht2U9r2qYip4TiDvyP6bP8uu1etzn86pmV6iXoFFf56RrC2OqAIfntn/7
 jwRX1jN47BrdUe5Pu6aNYlIpFATh349Y5aTOEzAMc5royKIcVJDinwlB+FpR+Uyr4sxH32OUzUm
 QdRVyOihfNK5iyBGYEOZi6kLMjvxEH5M2Qt4VYRE5Ro3ApooRp28mZaii9YI8IGKH5h4sojBb9t
 xq+UNf3NU4IryNA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

venus_add_video_core() checks whether the decoder or encoder node is
already present in the device tree with of_find_node_by_name(). That
function drops a reference on the node it starts from and searches the
rest of the whole tree rather than the children of that node, so every
probe drops two references on the video-codec node that the driver
never took.

Once the node's refcount reaches zero, which on SDM845 happens on the
first unload of venus_core, of_node_release() complains about a bad
of_node_put() and the node's sysfs directory is gone; the next probe
then crashes while attaching the dynamic child nodes:

  OF: ERROR: of_node_release() detected bad of_node_put() on /soc@0/video-codec@aa00000
  Unable to handle kernel NULL pointer dereference at virtual address 0000000000000008
  ...
  kernfs_find_and_get_ns+0x24/0x80
  safe_name+0x48/0xd8
  __of_attach_node_sysfs+0x58/0x118
  __of_attach_node+0x8c/0x170
  __of_changeset_entry_apply+0xe8/0x178
  __of_changeset_apply_entries+0x50/0x1e0
  of_changeset_apply+0x54/0xc0
  venus_add_dynamic_nodes+0xb4/0xe0 [venus_core]
  venus_probe+0x2f4/0x3c0 [venus_core]

Use of_get_child_by_name(), which only looks at the direct children,
where static codec nodes live, and leaves the parent's refcount alone.

Assisted-by: LLM
Fixes: 687bfbba5a1c ("media: venus: Add support for static video encoder/decoder declarations")
Reported-by: Dan Carpenter <dan.carpenter@linaro.org>
Closes: https://lore.kernel.org/all/aAuqgiSxrh24-L-D@stanley.mountain/
Signed-off-by: David Heidelberg <david@ixit.cz>
---
Unloading and reloading venus_core crashes on SDM845: every probe drops
two references on the video-codec node through of_find_node_by_name().

Tested on Pixel 3 (SDM845) with ten unload/reload cycles, decoding after
each one.
---
 drivers/media/platform/qcom/venus/core.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/media/platform/qcom/venus/core.c b/drivers/media/platform/qcom/venus/core.c
index 243e342b0ae75..3e69fc7ea3c79 100644
--- a/drivers/media/platform/qcom/venus/core.c
+++ b/drivers/media/platform/qcom/venus/core.c
@@ -301,17 +301,17 @@ static int venus_add_video_core(struct venus_core *core, const char *node_name,
 	struct of_changeset *ocs = core->ocs;
 	struct device *dev = core->dev;
 	struct device_node *np, *enp;
 	int ret;
 
 	if (!node_name)
 		return 0;
 
-	enp = of_find_node_by_name(dev->of_node, node_name);
+	enp = of_get_child_by_name(dev->of_node, node_name);
 	if (enp) {
 		of_node_put(enp);
 		return 0;
 	}
 
 	np = of_changeset_create_node(ocs, dev->of_node, node_name);
 	if (!np) {
 		dev_err(dev, "Unable to create new node\n");

---
base-commit: 7079a12d7506b07fb53b54a664bfad5fa9b16d70
change-id: 20260928-venus-of-node-ref-b69742ffa2c3

Best regards,
--  
David Heidelberg <david@ixit.cz>

