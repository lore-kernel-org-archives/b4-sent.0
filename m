From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH 0/2] media: verisilicon: av1: Fix two reference reads
Date: Sun, 15 Nov 2026 08:59:03 +0000
Message-Id: <20261115-b4-vpu981-av1-refs-v1-0-c65769715db9@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqEMAyF4atI1gZMKcPUq4iLauMYFyqNFkG8u
 9VZfg/ef4JyFFaoixMiJ1FZ5gwqC+hHP/8YJWSDqcyHiCx2FtO6uy+hT4SRB8XgLDk/kOEqQD6
 ueZXjjTbt37p3E/fbU4LrugFy+K5TdgAAAA==
X-Change-ID: 20261114-b4-vpu981-av1-refs-d9419af12e0d
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Heiko Stuebner <heiko@sntech.de>, Hans Verkuil <hverkuil@kernel.org>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 stable@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794733143; l=1051;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=KuW65qSSVnoaFOMXDWaytG4qSD+RtxeDkZRMmT3rxPk=;
 b=GOhE6FcdPqzO/RtJbvJshne/Kp5GWQEHTECh5RXURiF95TRQfXKzfe9d1oCbDfeH8DvnmWExC
 M/RJavEVeFIA1odvmPCM5B1scSIkoTHp/JQ0Wc7VbALqViO4CTSVN9r
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The RK3588 AV1 decoder (VPU981) can read a CAPTURE buffer freed with
VIDIOC_REMOVE_BUFS (patch 1), and reads the segmentation map past the
end of a smaller reference after a switch to a larger CAPTURE format
(patch 2).

Found by code review; neither was reproduced. Tested on an Orange Pi 5
(RK3588S), 7.3-based tree with these patches: fluster AV1 test vectors,
no new failures.

Developed with Claude (Anthropic), which wrote the code and the commit
messages. I reviewed every change.

---
Arun Iyengar (2):
      media: verisilicon: av1: Find the reference buffers by timestamp
      media: verisilicon: av1: Read the segmentation map at the reference's offset

 drivers/media/platform/verisilicon/hantro_hw.h     |  1 -
 .../verisilicon/rockchip_vpu981_hw_av1_dec.c       | 45 +++++++++++++---------
 2 files changed, 26 insertions(+), 20 deletions(-)
---
base-commit: 48fe5a7834cc10081887d7bcd9ff0a4cadc3fa8c
change-id: 20261114-b4-vpu981-av1-refs-d9419af12e0d

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

