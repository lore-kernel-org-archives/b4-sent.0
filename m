From: Christopher Griffin <christophergriffin05@gmail.com>
Subject: [PATCH ath-next 0/2] wifi: ath11k: HT, VHT and every stream for a
 QCN9074's 5 GHz band
Date: Wed, 28 Oct 2026 14:37:37 -0500
Message-Id: <20261028-b4-ath11k-qcn907x-caps-v1-0-c7daa6f1c02c@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAFP4moC/yWMQQrCMBAAv1L27EI21mj9inhI1tVGIbbZKIHSv
 xv1OAwzC6jkKArHboEs76jxmRrQpgMefboJxktjsMY6MvaAoUdfRqIHzpwGs6/IflKUXWByMgT
 Xb6HFU5ZrrL/xCVqASWqB89/oK9yFy/cL6/oBaXYnwoQAAAA=
X-Change-ID: 20261028-b4-ath11k-qcn907x-caps-e5bc16e9b643
To: Jeff Johnson <jjohnson@kernel.org>
Cc: linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793216257; l=1245;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=AjLNAMDDcP3b7jONTJ7plUs667CPRyqbSeh47AQDCV0=;
 b=eepb0BWoUWa5l0hDbw8eqkM/9iE1u5wIBrAXSJKQv3JWjZHtU5z5u+kESbCPEJLQlPOM7J8Jb
 PoxVW7lmYIJBWKeQfTT11hovGVlQKdHZxIgvw4EK3FEHN31iMCZSXzK
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two fixes to the capabilities ath11k registers, found on the QCN9072 of
an Arista C-360 (it takes the QCN9074's hw_params), which covers 2.4, 5
and 6 GHz.

The first gives a 6 GHz capable radio's 5 GHz band HT and VHT: without
them it used legacy rates only on 5 GHz.

The second counts a stream for every chain: the QCN9072's chainmask is
0x5, and ath11k offered one stream for it on every band.

With both, the QCN9072 as a 5 GHz client associated at HE-MCS 10, 2
streams, and ran 310 Mbit/s down and 438 up to a local server, where
before it managed 3-23 Mbit/s. The IPQ8074's radios, whose chainmasks
are contiguous, register the same capabilities as before.

Both apply to ath-next; the second is written on top of the first.

---
Christopher Griffin (2):
      wifi: ath11k: give a 6 GHz capable radio's 5 GHz band HT and VHT
      wifi: ath11k: advertise a spatial stream for every chain

 drivers/net/wireless/ath/ath11k/mac.c | 45 ++++++++++++++---------------------
 1 file changed, 18 insertions(+), 27 deletions(-)
---
base-commit: 7b14c8f4a9615579b09cbcdc4515b65ae6124753
change-id: 20261028-b4-ath11k-qcn907x-caps-e5bc16e9b643

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

