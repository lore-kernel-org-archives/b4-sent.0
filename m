From: Junrui Luo <moonafterrain@outlook.com>
Subject: [PATCH 0/2] drm/nouveau: fix unbounded kernel allocations in the
 VM_BIND uAPI
Date: Sat, 08 Aug 2026 19:14:16 +0800
Message-Id: <20260808-nouveau-fixes-v1-0-c3ebdc17a89c@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIgPd2oC/x3LQQqAIBBA0avErBOmxJSuEi2kxpqNhqIE4t2Tl
 o/Pr5AoMiVYhwqRCicOvmMaBzhu6y8SfHbDjPOCBo3wIReyWTh+KQmNVqOTTkmjoD9PpD/0Zdt
 b+wB+fx5PXwAAAA==
X-Change-ID: 20260808-nouveau-fixes-70a70f3f5385
To: Lyude Paul <lyude@redhat.com>, Danilo Krummrich <dakr@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Dave Airlie <airlied@redhat.com>
Cc: dri-devel@lists.freedesktop.org, nouveau@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, Junrui Luo <moonafterrain@outlook.com>, 
 Yuhao Jiang <danisjiang@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1742;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=qBJ2yKuCe+qydBAwBPNKgkU4vVCYc0ywAbFKq6nD8ZM=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrHIBi08MP5l7s2M5cmvP935cMcdbe8FB18a7p2qY4
 pM25joLhneUsjCIcTHIiimyHC+49M3Cd4vuFp8tyTBzWJlAhjBwcQrARMqaGf4Z2ulnzsx4d9bo
 58z72/0/zZwTbj9T+eCtRXNZ9KbJy5g9ZWSYuTR56f3IApbIlssn3+0oj+IVqd5T+CNHMNXYdfX
 hfnFGAOcWSP0=
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two independent fixes to the uAPI added by b88baab82871 ("drm/nouveau:
implement new VM_BIND uAPI").

Patch 1 bounds the sync and operation counts in EXEC and VM_BIND.
nouveau_exec_ucopy() and nouveau_uvmm_vm_bind_ucopy() hand user-supplied
u32 counts straight to u_memcpya(), which only rejects multiplication
overflow -- something a u32 count times a small element size never
reaches on 64-bit.  A wait_count of 0xffffffff thus becomes a 64 GB
vmemdup_user() request: above INT_MAX that trips the WARN_ON_ONCE() in
__kvmalloc_node_noprof(), and below it the kernel attempts a vmalloc of
up to 2 GB that GFP_USER leaves uncharged to the caller's memcg.

Patch 2 rejects a second VM_INIT.  nouveau_uvmm_ioctl_vm_init() never
checks whether the client already has a GPU VA space before overwriting
cli->uvmm.ptr, so a second call orphans the first nouveau_uvmm with no
remaining reference to it.  The orphan, its drm_gpuvm, that gpuvm's
reservation object and its region maple tree are never freed, the buffer
objects mapped in it stay pinned, and its nvif vmm keeps the GPU page
directories allocated until the file is closed.

Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
Junrui Luo (2):
      drm/nouveau: bound sync and op counts in EXEC and VM_BIND
      drm/nouveau/uvmm: reject a second VM_INIT

 drivers/gpu/drm/nouveau/nouveau_exec.c | 12 ++++++++++++
 drivers/gpu/drm/nouveau/nouveau_uvmm.c | 24 ++++++++++++++++++++++++
 include/uapi/drm/nouveau_drm.h         | 18 ++++++++++++++++++
 3 files changed, 54 insertions(+)
---
base-commit: 075b74841bd0065a3bda3440873c747938e69b68
change-id: 20260808-nouveau-fixes-70a70f3f5385

Best regards,
-- 
Junrui Luo <moonafterrain@outlook.com>

