From: Antonin Malzieu Ridolfi <dev@nanonej.com>
Subject: [PATCH 0/5] gpu: nova-core: Move registers definitions
Date: Wed, 17 Jun 2026 01:48:11 +0200
Message-Id: <20260617-nova-core-regs-split-v1-0-4c7dc4450ea7@nanonej.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDQAxA0atI1gY0lEF6ldJFnEaNlBlJVAri3
 Tuty7f4/wAXU3G4VweY7OqaU0FbVxAnTqOgvoqBGgpNaAOmvDPGbIImo6Mvb11RiLueKDIPNyj
 pYjLo5799PC/71s8S198LzvMLNB/BJngAAAA=
X-Change-ID: 20260616-nova-core-regs-split-e2a8b22caaf4
To: Danilo Krummrich <dakr@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, Alice Ryhl <aliceryhl@google.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Antonin Malzieu Ridolfi <dev@nanonej.com>
Cc: linux-kernel@vger.kernel.org, nova-gpu@lists.linux.dev, 
 dri-devel@lists.freedesktop.org, daniel.almeida@collabora.com
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1830; i=dev@nanonej.com;
 h=from:subject:message-id; bh=AUrgEM0wJ158ROniMN15XgMhloe3Kpw6MiRg7eAPnHg=;
 b=owEBbQKS/ZANAwAKAWaH8SMKFRX9AcsmYgBqMeDIwRhfARQzVs6K5Axbi9TCi+O00t32Fczqg
 gYuotuzHLeJAjMEAAEKAB0WIQSDtk+wfJEhL1KFIn1mh/EjChUV/QUCajHgyAAKCRBmh/EjChUV
 /e2uD/9nPRiXFqoQ/ey5OVKuULhCW/hWTuP14frrHdadVrCPZ0mgfH3XMFl+rZvCGTv8fJ1+pRS
 aK5G+EKW3HAC8XyxzJEfR79KH2+KjIPwNwwrv4VeL54EBQbl0NrbFTO1QrfInZa/WrU1Nml7+sy
 wzJrMPJdhXjzuvhM4ZWE0PEuOq6ilAfOGF1Z9XZbwN45y6OYfUYkS5+ThxCtJ6SYIKhm+QBHMp3
 7H5x5yk2852/v3QA97QVDldzrRBNYucigIBZMunbUurH7I1aliY0z6Cid77kj8xKTebZ//p922L
 bxxNmCMFst6beVx2bsQdgZrG1TJmtsxMzx6sL3y2YtVNRHUgoCqLfOgiXacGR10+HKqYZbrC8Iu
 k1YHNAOqY1BB0n5VH2qJuAQVj99BTcYZUNa2DQfgGjAuXr9gcGWAUYMDwXo2RwQSZ5Z92U8SCrK
 R6oW2CEu2aav1af1sYkHEY65cm7WHy/ATdLUpGMXluacf5/WZHCHbf1/kqkJixuijXiar403yFG
 QQ1j/Yeq3wNsFdvFtHGw5PG4sPVFNSVraXpQIo8UYOksgXzzU+8/DC33FCPK5+iPNTLDlpM31vg
 HfvfBhdJkLU78+brwhqYzgVuQbcFcmhY66D5R+A6GUz7qNhe2J5JM/pRhX+2tkzyG0Mbfaonr4E
 lw8Wqw5HlE0hE0Q==
X-Developer-Key: i=dev@nanonej.com; a=openpgp;
 fpr=83B64FB07C91212F5285227D6687F1230A1515FD
X-Endpoint-Received: by B4 Relay for dev@nanonej.com/default with auth_id=825
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Split part of the registers definitions grouped in nova root register file
to belonging modules whom actually use them.

To: Danilo Krummrich <dakr@kernel.org>
To: Alexandre Courbot <acourbot@nvidia.com>
To: Alice Ryhl <aliceryhl@google.com>
To: David Airlie <airlied@gmail.com>
To: Simona Vetter <simona@ffwll.ch>
To: Antonin Malzieu Ridolfi <dev@nanonej.com>
Cc: linux-kernel@vger.kernel.org
Cc: nova-gpu@lists.linux.dev
Cc: dri-devel@lists.freedesktop.org
Cc: daniel.almeida@collabora.com

Suggested-by: Alexandre Courbot <acourbot@nvidia.com>
Suggested-by: Danilo Krummrich <dakr@kernel.org>
Signed-off-by: Antonin Malzieu Ridolfi <dev@nanonej.com>
---
Antonin Malzieu Ridolfi (5):
      gpu: nova-core: fb: Move PDISP register definition
      gpu: nova-core: gsp: Move PBUS register definition
      gpu: nova-core: falcon: Move PFALCON2 register
      gpu: nova-core: falcon: Move PRISCV register
      gpu: nova-core: falcon: Move PFSP register

 drivers/gpu/nova-core/falcon.rs           |  71 +++++++++++---------
 drivers/gpu/nova-core/falcon/fsp.rs       |  14 ++--
 drivers/gpu/nova-core/falcon/hal/ga102.rs |  32 +++++----
 drivers/gpu/nova-core/falcon/hal/tu102.rs |   8 +--
 drivers/gpu/nova-core/falcon/regs.rs      |  76 +++++++++++++++++++++
 drivers/gpu/nova-core/fb.rs               |   4 +-
 drivers/gpu/nova-core/fb/regs.rs          |  25 +++++++
 drivers/gpu/nova-core/gsp/hal/tu102.rs    |  12 ++--
 drivers/gpu/nova-core/gsp/regs.rs         |  11 ++++
 drivers/gpu/nova-core/regs.rs             | 105 +-----------------------------
 10 files changed, 191 insertions(+), 167 deletions(-)
---
base-commit: 5f7410aa26524101d34b627fbe16670b1514962c
change-id: 20260616-nova-core-regs-split-e2a8b22caaf4

Best regards,
--  
Antonin Malzieu Ridolfi <dev@nanonej.com>

