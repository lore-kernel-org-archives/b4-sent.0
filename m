From: Suyuan Wang <shyckless@gmail.com>
Date: Tue, 17 Nov 2026 14:11:13 +0000
Subject: [PATCH] RDMA/iwcm: Require CAP_NET_ADMIN for iWARP port mapper
 netlink messages
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-iwpm-perm-v1-1-11f1b87d6fb3@gmail.com>
X-B4-Tracking: v=1; b=H4sIAIBg/GoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQ0Nz3czyglzdgtSiXN1UQyPz1MQ0C+O0VHMloPqCotS0zAqwWdGxEH5
 xaVJWanIJyACl2loARtq/Dm0AAAA=
X-Change-ID: 20261117-iwpm-perm-e127eaf83fe7
To: jgg@ziepe.ca, leon@kernel.org
Cc: linux-rdma@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794924672; l=4038;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=Z9OLDut2x9uLQu+jC2FkDVbLqTc8dEpPtoaL/tSmdPY=;
 b=qaZdEPa6aL8bjtmtf0yajNyMDGE2Rx6ALVatlyYq1jbLhkYwR7J0eROfA6jMZ27l+kzCjXFG4
 Y1hkQXJ6rKSAYnsOEti5nAqQUXLJCGxvC8xUX04TCer7d0yZpIADhoM
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

The RDMA_NL_IWCM callbacks process replies and notifications from the
port mapper daemon, iwpmd, but none of them sets RDMA_NL_ADMIN_PERM:

    [RDMA_NL_IWPM_REG_PID] = {.dump = iwpm_register_pid_cb},
    [RDMA_NL_IWPM_ADD_MAPPING] = {.dump = iwpm_add_mapping_cb},
    ...

so rdma_nl_rcv_msg() accepts them from any process in init_net.

iwpm_hello_cb() and iwpm_mapping_info_cb() set iwpm_user_pid to the
sender's port ID and mark the client IWPM_REG_INCOMPL, without matching
any pending kernel request. An unprivileged process can thus make
itself the daemon that the kernel sends port mapper requests to. The
mapping replies are matched against the request they answer, but
nothing checks that the sender is the port mapper, and the address a
matching reply carries is the one iw_cm_map() uses.

Set RDMA_NL_ADMIN_PERM on all iwcm callbacks, so the RDMA netlink
dispatcher requires CAP_NET_ADMIN before invoking them. This matches
the RDMA_NL_LS response handlers, which already require it, and iwpmd
runs as root.

Found with a static analysis tool and checked by hand.

Fixes: b493d91d333e ("iwcm: common code for port mapper")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Tested under QEMU (x86_64, CONFIG_INFINIBAND=y): before this patch a
process in a child user namespace, with no CAP_NET_ADMIN over
init_user_ns, can send an RDMA_NL_IWCM message that reaches the
port-mapper callbacks; after it the dispatcher returns -EPERM. A
privileged sender still reaches them. W=1 and sparse show no new
warnings. I don't have iWARP hardware. The upstream iwpmd systemd
service runs as root without a capability bounding set, so it keeps
CAP_NET_ADMIN.

Related discussion of unprivileged access to this interface:
https://lore.kernel.org/linux-rdma/20261109200330.2361828-1-graypanda.inzag@gmail.com/
That patch fixes a REMOTE_INFO allocation leak; this one adds the
missing privilege check for all the IWCM port-mapper callbacks.
---
 drivers/infiniband/core/iwcm.c | 40 ++++++++++++++++++++++++++++++++--------
 1 file changed, 32 insertions(+), 8 deletions(-)

diff --git a/drivers/infiniband/core/iwcm.c b/drivers/infiniband/core/iwcm.c
index 4b05867dad89..94a92434063a 100644
--- a/drivers/infiniband/core/iwcm.c
+++ b/drivers/infiniband/core/iwcm.c
@@ -81,14 +81,38 @@ const char *__attribute_const__ iwcm_reject_msg(int reason)
 EXPORT_SYMBOL(iwcm_reject_msg);
 
 static struct rdma_nl_cbs iwcm_nl_cb_table[RDMA_NL_IWPM_NUM_OPS] = {
-	[RDMA_NL_IWPM_REG_PID] = {.dump = iwpm_register_pid_cb},
-	[RDMA_NL_IWPM_ADD_MAPPING] = {.dump = iwpm_add_mapping_cb},
-	[RDMA_NL_IWPM_QUERY_MAPPING] = {.dump = iwpm_add_and_query_mapping_cb},
-	[RDMA_NL_IWPM_REMOTE_INFO] = {.dump = iwpm_remote_info_cb},
-	[RDMA_NL_IWPM_HANDLE_ERR] = {.dump = iwpm_mapping_error_cb},
-	[RDMA_NL_IWPM_MAPINFO] = {.dump = iwpm_mapping_info_cb},
-	[RDMA_NL_IWPM_MAPINFO_NUM] = {.dump = iwpm_ack_mapping_info_cb},
-	[RDMA_NL_IWPM_HELLO] = {.dump = iwpm_hello_cb}
+	[RDMA_NL_IWPM_REG_PID] = {
+		.dump = iwpm_register_pid_cb,
+		.flags = RDMA_NL_ADMIN_PERM,
+	},
+	[RDMA_NL_IWPM_ADD_MAPPING] = {
+		.dump = iwpm_add_mapping_cb,
+		.flags = RDMA_NL_ADMIN_PERM,
+	},
+	[RDMA_NL_IWPM_QUERY_MAPPING] = {
+		.dump = iwpm_add_and_query_mapping_cb,
+		.flags = RDMA_NL_ADMIN_PERM,
+	},
+	[RDMA_NL_IWPM_REMOTE_INFO] = {
+		.dump = iwpm_remote_info_cb,
+		.flags = RDMA_NL_ADMIN_PERM,
+	},
+	[RDMA_NL_IWPM_HANDLE_ERR] = {
+		.dump = iwpm_mapping_error_cb,
+		.flags = RDMA_NL_ADMIN_PERM,
+	},
+	[RDMA_NL_IWPM_MAPINFO] = {
+		.dump = iwpm_mapping_info_cb,
+		.flags = RDMA_NL_ADMIN_PERM,
+	},
+	[RDMA_NL_IWPM_MAPINFO_NUM] = {
+		.dump = iwpm_ack_mapping_info_cb,
+		.flags = RDMA_NL_ADMIN_PERM,
+	},
+	[RDMA_NL_IWPM_HELLO] = {
+		.dump = iwpm_hello_cb,
+		.flags = RDMA_NL_ADMIN_PERM,
+	},
 };
 
 static struct workqueue_struct *iwcm_wq;



