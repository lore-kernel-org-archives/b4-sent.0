From: Eric Davis <eric.davis@broadcom.com>
Date: Wed, 14 Oct 2026 15:21:12 -0700
Subject: [PATCH rdma-next 03/13] RDMA/core: report the reliable unconnected
 device capabilities
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261014-uet-ib-core-v1-3-a0e626117113@broadcom.com>
References: <20261014-uet-ib-core-v1-0-a0e626117113@broadcom.com>
In-Reply-To: <20261014-uet-ib-core-v1-0-a0e626117113@broadcom.com>
To: Jason Gunthorpe <jgg@ziepe.ca>, Leon Romanovsky <leon@kernel.org>
Cc: linux-rdma@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Eric Davis <eric.davis@broadcom.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792016478; l=4489;
 i=eric.davis@broadcom.com; s=20261014; h=from:subject:message-id;
 bh=0vggS3kxYqLouN3EkZY+uyQtSRkdqNXoiZQOh4hHx1U=;
 b=iK6T7YSFxiGXf2cmJ/r2FKQkkJynVSD55RohTUp1Opi0WIY8p3Q+/KzZWD01lN8DuHwpov3XA
 QabvwZvJI8RAPq6PMH4rZysnrIWoOg3B2K3q4CHtXx7OaZgk0zA6fzl
X-Developer-Key: i=eric.davis@broadcom.com; a=ed25519;
 pk=uy3oCTOYBipIPjryXGMynBmtPvbO6qN2FOrduzpiI4A=
X-Endpoint-Received: by B4 Relay for eric.davis@broadcom.com/20261014 with auth_id=1186
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the capability bits a device uses to advertise reliable unconnected
support alongside additional features. The transport itself, 64-bit
immediate data, 64-bit memory keys, caller-chosen keys, and the four
memory region access restrictions.

Report the job, job key, and address table limits through the extended
query_device response so userspace can size against them.

Signed-off-by: Eric Davis <eric.davis@broadcom.com>
---
 drivers/infiniband/core/uverbs_cmd.c |  3 +++
 include/rdma/ib_verbs.h              | 14 ++++++++++++++
 include/uapi/rdma/ib_user_verbs.h    | 25 +++++++++++++++++++++++++
 3 files changed, 42 insertions(+)

diff --git a/drivers/infiniband/core/uverbs_cmd.c b/drivers/infiniband/core/uverbs_cmd.c
index aca7c6ab55cd..ed55fbbdfc18 100644
--- a/drivers/infiniband/core/uverbs_cmd.c
+++ b/drivers/infiniband/core/uverbs_cmd.c
@@ -3597,6 +3597,9 @@ static int ib_uverbs_ex_query_device(struct uverbs_attr_bundle *attrs)
 	resp.cq_moderation_caps.max_cq_moderation_period =
 		attr.cq_caps.max_cq_moderation_period;
 	resp.max_dm_size = attr.max_dm_size;
+	resp.max_job_ids = attr.max_job_ids;
+	resp.max_job_keys = attr.max_job_keys;
+	resp.max_addr_entries = attr.max_addr_entries;
 	resp.response_length = uverbs_response_length(attrs, sizeof(resp));
 
 	return uverbs_response(attrs, &resp, sizeof(resp));
diff --git a/include/rdma/ib_verbs.h b/include/rdma/ib_verbs.h
index 4e3a5c38cbe8..02f3312c7cf2 100644
--- a/include/rdma/ib_verbs.h
+++ b/include/rdma/ib_verbs.h
@@ -278,6 +278,14 @@ enum ib_device_cap_flags {
 	IB_DEVICE_FLUSH_PERSISTENT = IB_UVERBS_DEVICE_FLUSH_PERSISTENT,
 	IB_DEVICE_ATOMIC_WRITE = IB_UVERBS_DEVICE_ATOMIC_WRITE,
 	IB_DEVICE_CC_DMA_BOUNCE = IB_UVERBS_DEVICE_CC_DMA_BOUNCE,
+	IB_DEVICE_RU = IB_UVERBS_DEVICE_RU,
+	IB_DEVICE_IMM64 = IB_UVERBS_DEVICE_IMM64,
+	IB_DEVICE_KEY64 = IB_UVERBS_DEVICE_KEY64,
+	IB_DEVICE_USER_RKEY = IB_UVERBS_DEVICE_USER_RKEY,
+	IB_DEVICE_MR_UNRESTRICTED = IB_UVERBS_DEVICE_MR_UNRESTRICTED,
+	IB_DEVICE_MR_JOB_RESTRICTED = IB_UVERBS_DEVICE_MR_JOB_RESTRICTED,
+	IB_DEVICE_MR_QP_RESTRICTED = IB_UVERBS_DEVICE_MR_QP_RESTRICTED,
+	IB_DEVICE_MR_QP_JOB_RESTRICTED = IB_UVERBS_DEVICE_MR_QP_JOB_RESTRICTED,
 };
 
 enum ib_kernel_cap_flags {
@@ -456,6 +464,12 @@ struct ib_device_attr {
 	u64			max_dm_size;
 	/* Max entries for sgl for optimized performance per READ */
 	u32			max_sgl_rd;
+	/* Jobs allocated at once, not the largest JobID */
+	u32			max_job_ids;
+	/* Job keys allocated at once */
+	u32			max_job_keys;
+	/* Largest address table a single job may have */
+	u32			max_addr_entries;
 };
 
 enum ib_mtu {
diff --git a/include/uapi/rdma/ib_user_verbs.h b/include/uapi/rdma/ib_user_verbs.h
index 565301594634..bae6fcfa01dd 100644
--- a/include/uapi/rdma/ib_user_verbs.h
+++ b/include/uapi/rdma/ib_user_verbs.h
@@ -300,6 +300,10 @@ struct ib_uverbs_ex_query_device_resp {
 	__aligned_u64 max_dm_size;
 	__u32 xrc_odp_caps;
 	__u32 reserved;
+	__u32 max_job_ids; /* jobs allocated at once, not a JobID */
+	__u32 max_job_keys; /* job keys allocated at once */
+	__u32 max_addr_entries; /* largest address table of one job */
+	__u32 reserved2;
 };
 
 struct ib_uverbs_query_port {
@@ -1370,6 +1374,27 @@ enum ib_uverbs_device_cap_flags {
 	IB_UVERBS_DEVICE_ATOMIC_WRITE = 1ULL << 40,
 	/* CoCo guest with DMA bounce buffering required */
 	IB_UVERBS_DEVICE_CC_DMA_BOUNCE = 1ULL << 41,
+	/* Reliable unconnected QPs, jobs, job keys and address tables */
+	IB_UVERBS_DEVICE_RU = 1ULL << 42,
+	/* 64-bit immediate data */
+	IB_UVERBS_DEVICE_IMM64 = 1ULL << 43,
+	/* An MR may carry 64-bit keys as a second name beside its 32-bit ones */
+	IB_UVERBS_DEVICE_KEY64 = 1ULL << 44,
+	/* MR registration with a caller-chosen rkey */
+	IB_UVERBS_DEVICE_USER_RKEY = 1ULL << 45,
+	/*
+	 * MR access restrictions, meaningful only with IB_UVERBS_DEVICE_RU.
+	 * Each names what an incoming request must match, and each is its own
+	 * match: supporting two does not imply their combination.
+	 */
+	/* PD: any QP */
+	IB_UVERBS_DEVICE_MR_UNRESTRICTED = 1ULL << 46,
+	/* PD and JobID: any QP, one job */
+	IB_UVERBS_DEVICE_MR_JOB_RESTRICTED = 1ULL << 47,
+	/* PD and QP: the QP the MR is attached to */
+	IB_UVERBS_DEVICE_MR_QP_RESTRICTED = 1ULL << 48,
+	/* PD, QP and JobID: the attached QP, one job */
+	IB_UVERBS_DEVICE_MR_QP_JOB_RESTRICTED = 1ULL << 49,
 };
 
 enum ib_uverbs_raw_packet_caps {

-- 
2.56.0

