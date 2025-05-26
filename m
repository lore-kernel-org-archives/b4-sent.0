From: Mahesh Rao <mahesh.rao@altera.com>
Date: Mon, 26 May 2025 14:25:04 +0800
Subject: [PATCH v3 1/4] firmware: stratix10-svc: Add mutex lock and unlock
 in stratix10 memory allocation/free
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250526-sip_svc_upstream-v3-1-6a08a4502de3@altera.com>
References: <20250526-sip_svc_upstream-v3-0-6a08a4502de3@altera.com>
In-Reply-To: <20250526-sip_svc_upstream-v3-0-6a08a4502de3@altera.com>
To: Dinh Nguyen <dinguyen@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Mahesh Rao <mahesh.rao@altera.com>
Cc: Matthew Gerlach <matthew.gerlach@altera.com>, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1748240732; l=3909;
 i=mahesh.rao@altera.com; s=20250107; h=from:subject:message-id;
 bh=U7peSYw634W0vjNlQpTtWPEU2kILWkLlInRHSfUpC/A=;
 b=6Y/V/7nY2o+pyobP4VVlFbwRxcUFyV2LHH9DDODxjbOOlryctvQpmWG/7nveuIYuxYL6ed0JZ
 R5E+ctiVzpsBOIo42RjKbeYTBYnuARVMcbusMPt+P+v+YFQhU+WqAGm
X-Developer-Key: i=mahesh.rao@altera.com; a=ed25519;
 pk=tQiFUzoKxHrQLDtWeEeaeTeJTl/UfclUHWZy1fjSiyg=
X-Endpoint-Received: by B4 Relay for mahesh.rao@altera.com/20250107 with auth_id=337
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit adds a mutex lock to stratix10_svc_allocate_memory
and stratix10_svc_free_memory functions to ensure
thread safety when allocating and freeing memory.
This prevents potential race conditions and ensures
synchronization.

Signed-off-by: Mahesh Rao <mahesh.rao@altera.com>
Reviewed-by: Matthew Gerlach <matthew.gerlach@altera.com>
---
 drivers/firmware/stratix10-svc.c | 29 ++++++++++++++++++++++-------
 1 file changed, 22 insertions(+), 7 deletions(-)

diff --git a/drivers/firmware/stratix10-svc.c b/drivers/firmware/stratix10-svc.c
index e3f990d888d71829f0ab22b8a59aa7af0316bea0..3d42d4b18b7299d0a9e5110159e06253dfeddf88 100644
--- a/drivers/firmware/stratix10-svc.c
+++ b/drivers/firmware/stratix10-svc.c
@@ -1,6 +1,7 @@
 // SPDX-License-Identifier: GPL-2.0
 /*
  * Copyright (C) 2017-2018, Intel Corporation
+ * Copyright (C) 2025, Altera Corporation
  */
 
 #include <linux/completion.h>
@@ -171,6 +172,7 @@ struct stratix10_svc_chan {
 
 static LIST_HEAD(svc_ctrl);
 static LIST_HEAD(svc_data_mem);
+static DEFINE_MUTEX(svc_mem_lock);
 
 /**
  * svc_pa_to_va() - translate physical address to virtual address
@@ -182,14 +184,17 @@ static LIST_HEAD(svc_data_mem);
 static void *svc_pa_to_va(unsigned long addr)
 {
 	struct stratix10_svc_data_mem *pmem;
+	void *ret = NULL;
 
 	pr_debug("claim back P-addr=0x%016x\n", (unsigned int)addr);
+	mutex_lock(&svc_mem_lock);
 	list_for_each_entry(pmem, &svc_data_mem, node)
-		if (pmem->paddr == addr)
-			return pmem->vaddr;
-
-	/* physical address is not found */
-	return NULL;
+		if (pmem->paddr == addr) {
+			/* physical address is found */
+			ret = pmem->vaddr;
+		}
+	mutex_unlock(&svc_mem_lock);
+	return ret;
 }
 
 /**
@@ -990,13 +995,16 @@ int stratix10_svc_send(struct stratix10_svc_chan *chan, void *msg)
 			p_data->flag = ct->flags;
 		}
 	} else {
+		mutex_lock(&svc_mem_lock);
 		list_for_each_entry(p_mem, &svc_data_mem, node)
 			if (p_mem->vaddr == p_msg->payload) {
 				p_data->paddr = p_mem->paddr;
 				p_data->size = p_msg->payload_length;
 				break;
 			}
+		mutex_unlock(&svc_mem_lock);
 		if (p_msg->payload_output) {
+			mutex_lock(&svc_mem_lock);
 			list_for_each_entry(p_mem, &svc_data_mem, node)
 				if (p_mem->vaddr == p_msg->payload_output) {
 					p_data->paddr_output =
@@ -1005,6 +1013,7 @@ int stratix10_svc_send(struct stratix10_svc_chan *chan, void *msg)
 						p_msg->payload_length_output;
 					break;
 				}
+			mutex_unlock(&svc_mem_lock);
 		}
 	}
 
@@ -1072,9 +1081,12 @@ void *stratix10_svc_allocate_memory(struct stratix10_svc_chan *chan,
 	if (!pmem)
 		return ERR_PTR(-ENOMEM);
 
+	mutex_lock(&svc_mem_lock);
 	va = gen_pool_alloc(genpool, s);
-	if (!va)
+	if (!va) {
+		mutex_unlock(&svc_mem_lock);
 		return ERR_PTR(-ENOMEM);
+	}
 
 	memset((void *)va, 0, s);
 	pa = gen_pool_virt_to_phys(genpool, va);
@@ -1086,6 +1098,7 @@ void *stratix10_svc_allocate_memory(struct stratix10_svc_chan *chan,
 	pr_debug("%s: va=%p, pa=0x%016x\n", __func__,
 		 pmem->vaddr, (unsigned int)pmem->paddr);
 
+	mutex_unlock(&svc_mem_lock);
 	return (void *)va;
 }
 EXPORT_SYMBOL_GPL(stratix10_svc_allocate_memory);
@@ -1100,6 +1113,7 @@ EXPORT_SYMBOL_GPL(stratix10_svc_allocate_memory);
 void stratix10_svc_free_memory(struct stratix10_svc_chan *chan, void *kaddr)
 {
 	struct stratix10_svc_data_mem *pmem;
+	mutex_lock(&svc_mem_lock);
 
 	list_for_each_entry(pmem, &svc_data_mem, node)
 		if (pmem->vaddr == kaddr) {
@@ -1107,9 +1121,10 @@ void stratix10_svc_free_memory(struct stratix10_svc_chan *chan, void *kaddr)
 				       (unsigned long)kaddr, pmem->size);
 			pmem->vaddr = NULL;
 			list_del(&pmem->node);
+			mutex_unlock(&svc_mem_lock);
 			return;
 		}
-
+	mutex_unlock(&svc_mem_lock);
 	list_del(&svc_data_mem);
 }
 EXPORT_SYMBOL_GPL(stratix10_svc_free_memory);

-- 
2.35.3

