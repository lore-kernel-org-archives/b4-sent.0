From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Subject: [PATCH v2 0/2] drm/msm/adreno: Add Adreno 829 support
Date: Fri, 20 Nov 2026 21:22:36 +0530
Message-Id: <20261120-molokai-a829-v2-0-c63c268d5ab3@yahoo.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNQQ6CMBBFr0JmbU2nCKGuuIdh0dYio8KYFomE9
 O4Crl2+5P33F4g+kI9wzhYIfqJIPKygDhm4zgw3L+i6MiipSkQsRc9PfhgSplJaaGerQupcojr
 BOnkF39Jnz12aH8e3vXs3bo3N6CiOHOb9b8LN+5OeUEjR2lzKwrZGK6xn0zEfHffQpJS+wF/h0
 roAAAA=
X-Change-ID: 20261116-molokai-a829-9cb850930124
To: Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, Sean Paul <sean@poorly.run>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Konrad Dybcio <konradybcio@kernel.org>, 
 Akhil P Oommen <akhilpo@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Venkat Yadlapati <venkat.yadlapati@yahoo.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795189956; l=2690;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=SB/YDmRW4o+ak+TUitU4f8OfQWSywzEFHMWLx5BFo1k=;
 b=U7ZmEKfGozpKWW24mLPOggF8CqlEbLJAPr+rt8kJzl7znAgPmdcrQZYW6/DNlOfTMWMp+Eu3N
 IALFg1qThDIBiNMCxvW4tjoaVzVX26aaZIPQUS9pJ3N+kXDM0TSQjOU
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Qualcomm Molokai (SM8845) SoC has an Adreno 829 (gen8_9_0), a two
slice variant of the Adreno 840 with a smaller GMEM, its own firmware and
a smaller preemption record. This documents its GMU and adds it to the
a8xx catalog.

On msm-next it needs "drm/msm/a6xx: Fall back to MX when GMxC has no
levels" to boot, since the Molokai command DB lists gmxc.lvl without
levels. The SoC devicetree is sent separately in "Add support for the
Qualcomm Molokai (SM8845) and the Motorola Signature".

Tested on the Motorola Signature with the gen80900 firmware: the GPU
boots and Phosh renders on it with freedreno (Mesa needs the msm chip id
0xffff44030a20 added to its A829 entry, which only has the KGSL one).

I used an LLM (Claude) to help write these patches and their commit
messages. I reviewed all of them and tested the result on the device.

---
Changes in v2:
- Drop the Assisted-by trailers and the LLM notes from the commit
  messages, the LLM use is stated in this cover letter.
- Explain in the commit message why the A840 CLX and limits tables
  are not reused.
- Link to v1: https://patch.msgid.link/20261116-molokai-a829-v1-0-fb3005bfa921@yahoo.com

To: Rob Clark <robin.clark@oss.qualcomm.com>
To: Dmitry Baryshkov <lumag@kernel.org>
To: Abhinav Kumar <abhinav.kumar@linux.dev>
To: Jessica Zhang <jesszhan0024@gmail.com>
To: Sean Paul <sean@poorly.run>
To: Marijn Suijten <marijn.suijten@somainline.org>
To: David Airlie <airlied@gmail.com>
To: Simona Vetter <simona@ffwll.ch>
To: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>
To: Maxime Ripard <mripard@kernel.org>
To: Thomas Zimmermann <tzimmermann@suse.de>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Konrad Dybcio <konradybcio@kernel.org>
To: Akhil P Oommen <akhilpo@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org
Cc: dri-devel@lists.freedesktop.org
Cc: freedreno@lists.freedesktop.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
Venkat Yadlapati (2):
      dt-bindings: display/msm/gmu: Document Adreno 829 GMU
      drm/msm/adreno: Add Adreno 829 support

 .../devicetree/bindings/display/msm/gmu.yaml       |   4 +-
 drivers/gpu/drm/msm/adreno/a6xx_gmu.c              |   3 +-
 drivers/gpu/drm/msm/adreno/a8xx_catalog.c          | 100 +++++++++++++++++++++
 drivers/gpu/drm/msm/adreno/adreno_gpu.h            |   5 ++
 4 files changed, 110 insertions(+), 2 deletions(-)
---
base-commit: d024361c631b3f020a26c07d683e5103404b0fbf
change-id: 20261116-molokai-a829-9cb850930124

Best regards,
--  
Venkat Yadlapati <venkat.yadlapati@yahoo.com>

