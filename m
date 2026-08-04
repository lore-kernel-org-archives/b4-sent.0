From: Junrui Luo <moonafterrain@outlook.com>
Date: Tue, 04 Aug 2026 18:55:02 +0800
Subject: [PATCH 2/5] NFSv4/flexfiles: fix da_netid leak in
 nfs4_ff_alloc_deviceid_node()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260804-nfs-fixes-v1-2-1544df970e7c@outlook.com>
References: <20260804-nfs-fixes-v1-0-1544df970e7c@outlook.com>
In-Reply-To: <20260804-nfs-fixes-v1-0-1544df970e7c@outlook.com>
To: Trond Myklebust <trondmy@kernel.org>, Anna Schumaker <anna@kernel.org>
Cc: linux-nfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jonathan Curley <jcurley@purestorage.com>, 
 Michael Bommarito <michael.bommarito@gmail.com>, 
 Junrui Luo <moonafterrain@outlook.com>, Yuhao Jiang <danisjiang@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1642;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=Js0koCYPuEad0TbgAqXuAe69HQlQTlIjrIH4OepFPu4=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrMKjMoU1QradKx7FHXlzc98DHi5PE/8DPLd2b5I5u
 EvuYavDy+cdpSwMYlwMsmKKLMcLLn2z8N2iu8VnSzLMHFYmkCEMXJwCMBHPRQz/Yy69X7nKIUnY
 1NOx8lB74sJl29VirrOmOjo8K3FIq/L9wMhw7NK72JU+4Y+nFXX7807bvO3EGYdp0978vyrlezt
 ZSJeTBwBJH0zC
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

nfs4_decode_mp_ds_addr() allocates the r_netid string and hands ownership
to the nfs4_pnfs_ds_addr it returns. Both loops in
nfs4_ff_alloc_deviceid_node() that drain the local dsaddrs list free only
da_remotestr and the da itself, so the netid is leaked.

The success-path loop runs when nfs4_pnfs_ds_add() finds an equivalent
data server already cached and leaves the caller's list intact; the
out_err_drain_dsaddrs loop runs on every late failure in the function.

da_remotestr and da_netid are the only heap pointers in the structure, so
free both, as nfs4_pnfs_ds_addr_free() does.

Fixes: 4be78d26810b ("NFSv4/pNFS: Store the transport type in struct nfs4_pnfs_ds_addr")
Reported-by: Yuhao Jiang <danisjiang@gmail.com>
Assisted-by: Claude:claude-opus-5
Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
 fs/nfs/flexfilelayout/flexfilelayoutdev.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/fs/nfs/flexfilelayout/flexfilelayoutdev.c b/fs/nfs/flexfilelayout/flexfilelayoutdev.c
index 659a2bf7b502..98d464f402d5 100644
--- a/fs/nfs/flexfilelayout/flexfilelayoutdev.c
+++ b/fs/nfs/flexfilelayout/flexfilelayoutdev.c
@@ -169,6 +169,7 @@ nfs4_ff_alloc_deviceid_node(struct nfs_server *server, struct pnfs_device *pdev,
 				      da_node);
 		list_del_init(&da->da_node);
 		kfree(da->da_remotestr);
+		kfree(da->da_netid);
 		kfree(da);
 	}
 
@@ -181,6 +182,7 @@ nfs4_ff_alloc_deviceid_node(struct nfs_server *server, struct pnfs_device *pdev,
 				      da_node);
 		list_del_init(&da->da_node);
 		kfree(da->da_remotestr);
+		kfree(da->da_netid);
 		kfree(da);
 	}
 

-- 
2.51.2

