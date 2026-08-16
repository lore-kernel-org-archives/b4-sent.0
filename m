From: Junrui Luo <moonafterrain@outlook.com>
Subject: [PATCH 0/2] drm/amdgpu/userq: fix a leaked fence driver and an
 unlocked doorbell walk
Date: Mon, 17 Aug 2026 00:11:17 +0800
Message-Id: <20260817-amdgpu-fixes-v1-0-36d5298da646@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACXhgWoC/x3LQQqAIBBA0avIrBNUULSrRAvRyWaRiVIE0t2Tl
 o/P79CwEjaYWYeKNzU684CcGITd54Sc4jAooYyw0nB/xFQuvtGDjUsbnXbWWx08jKVU/MM4lvV
 9P+N5n4deAAAA
X-Change-ID: 20260816-amdgpu-fixes-18d9598a85ca
To: Alex Deucher <alexander.deucher@amd.com>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Sumit Semwal <sumit.semwal@linaro.org>, Sunil Khatri <sunil.khatri@amd.com>, 
 "Jesse.Zhang" <Jesse.Zhang@amd.com>
Cc: amd-gfx@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, linux-media@vger.kernel.org, 
 linaro-mm-sig@lists.linaro.org, Junrui Luo <moonafterrain@outlook.com>, 
 Yuhao Jiang <danisjiang@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1063;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=F2ekJeE+WuqeAaVxK/jJWMpPvhrgloRK3OiNqJW1IyQ=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrMaHGqH3leYU86UqPzPpmOS856qDxupfaY8ua9qF8
 ly8V7ry9tmOUhYGMS4GWTFFluMFl75Z+G7R3eKzJRlmDisTyBAGLk4BmMiCrwz/Hfh2Vf1elrln
 6evDwrOZVkwR473dNaPlq9eewosvpcUaIxgZrnJov7Wojtics1aeZZWc5qIr3aIzlzYkbHeI/5t
 +k+UPHwBTZkyn
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Patch 1 cancels the fences still linked on a queue's fence driver when the
queue goes away.  Each of them holds a reference on the driver, so its
refcount never reaches zero and the seq64 slot stays allocated for the
lifetime of the device.

Patch 2 holds xa_lock_irqsave() across the doorbell xarray walk in
mes_userq_detect_and_reset().  That xarray is device wide, so the walk
dereferences queues owned by other drm_files, and nothing keeps them alive
for its duration.

Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
Junrui Luo (2):
      drm/amdgpu/userq: cancel linked fences on fence driver free
      drm/amdgpu/userq: hold the doorbell xa lock during hang reset

 drivers/gpu/drm/amd/amdgpu/amdgpu_userq_fence.c | 71 ++++++++++++++++---------
 drivers/gpu/drm/amd/amdgpu/mes_userqueue.c      | 13 ++++-
 2 files changed, 57 insertions(+), 27 deletions(-)
---
base-commit: f5bbbfec59b4e2fb7520a91de3df8a6174325d6a
change-id: 20260816-amdgpu-fixes-18d9598a85ca

Best regards,
-- 
Junrui Luo <moonafterrain@outlook.com>

