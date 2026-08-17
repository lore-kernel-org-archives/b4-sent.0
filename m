From: Junrui Luo <moonafterrain@outlook.com>
Subject: [PATCH 0/2] drm/nouveau: fix out-of-bounds VRAM access and VM_BIND
 page-size mismatch
Date: Mon, 17 Aug 2026 14:50:39 +0800
Message-Id: <20260817-nouveau-fixes-v1-0-f518d0c735f3@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAD+vgmoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDC0Nz3bz80rLUxFLdtMyK1GJdI2MLc3MLE9Nk48QkJaCegqJUsARQS3R
 sbS0AIPyWx18AAAA=
X-Change-ID: 20260817-nouveau-fixes-23877845c3ab
To: Lyude Paul <lyude@redhat.com>, Danilo Krummrich <dakr@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Balbir Singh <balbirs@nvidia.com>, Mary Guillemard <mary@mary.zone>, 
 Mohamed Ahmed <mohamedahmedegypt2001@gmail.com>, 
 James Jones <jajones@nvidia.com>
Cc: dri-devel@lists.freedesktop.org, nouveau@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, Junrui Luo <moonafterrain@outlook.com>, 
 Yuhao Jiang <danisjiang@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1329;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=u/VaKggcAOLEcGn3Y0lUjyHfOlHj39Ku/qCdC+XjX+M=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrKb1DskN65l1HvV2Gn0WWd6l+6pxq8KdBMs357hnN
 vsvjuD/u6yjlIVBjItBVkyR5XjBpW8Wvlt0t/hsSYaZw8oEMoSBi1MAJjLvKMN/n93uaXl7lH71
 1PQdu5PkcFuIQ8bm/rFZF7nfTKpRul9yg5HhSv2bRfWmDg8lLzxYPynz1d1VPnPquyp/v2qXF2n
 qm72bGwBBAE9E
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two unrelated fixes; they touch different files and can be applied
independently.

Patch 1 sizes the VRAM buffer object backing a device-private region to
the region it actually backs. The region grew to DMEM_CHUNK_SIZE *
NR_CHUNKS while the buffer object stayed at DMEM_CHUNK_SIZE, so
nouveau_dmem_page_addr() resolves every page past the first chunk to VRAM
outside the object.

Patch 2 rejects a VM_BIND that replaces a mapping with one using a
different page size. A new mapping takes over the page tables of the
mappings it replaces, which only holds while they all use the same page
size. Since select_page_shift() started deriving one per mapping it no
longer does, and the new mapping ends up mapping at a size its page
tables were never built for.

Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
Junrui Luo (2):
      drm/nouveau/dmem: pin VRAM for the whole registered range
      drm/nouveau/uvmm: reject replace across page sizes

 drivers/gpu/drm/nouveau/nouveau_dmem.c |  4 ++--
 drivers/gpu/drm/nouveau/nouveau_uvmm.c | 33 ++++++++++++++++++++++++++++++++-
 2 files changed, 34 insertions(+), 3 deletions(-)
---
base-commit: f5bbbfec59b4e2fb7520a91de3df8a6174325d6a
change-id: 20260817-nouveau-fixes-23877845c3ab

Best regards,
-- 
Junrui Luo <moonafterrain@outlook.com>

