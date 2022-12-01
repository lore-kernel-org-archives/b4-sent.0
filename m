Subject: [PATCH RESEND v11 0/2] Completely fake series
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
From: Konstantin =?utf-8?q?Ry=C3=A0bitsev?= <mricon@gmail.com>
Date: Thu, 01 Dec 2022 16:04:49 -0500
Message-Id: <20220825-test-endpoint-send-2-v11-0-ac6c8bd3211c@gmail.com>
To: =?utf-8?q?T=C3=A9sting_T=C3=A9st?= <mricon@kernel.org>
X-Mailer: b4 0.11.0-dev-6404c
X-Developer-Signature: v=1; a=openpgp-sha256; l=2010; i=mricon@gmail.com;
 h=from:subject:message-id; bh=KPNjO9KSCD1qMoBAVi9qUiD0Ik76qdgGOcYqbMtxAvQ=;
 b=owGbwMvMwCW27YjM47CUmTmMp9WSGJI7xX74W8aefbDv8r3wtgBNbplJnGeW/ksRmd0se1t0V2r7
 Mv1XHaUsDGJcDLJiiixl+2I3BRU+9JBL7zGFmcPKBDKEgYtTACay8Tojwwmn/uR96z0Vjxq53zHfNO
 fjxwdcRy94Jt2L4tM4t7MpWoSRoetRoHm9V7dIt35S9UOjdRGvmq6/997i0B4kMffm7dXtbAA=
X-Developer-Key: i=mricon@gmail.com; a=openpgp;
 fpr=DE0E66E32F1FDD0902666B96E63EDCA9329DD07E
X-Endpoint-Received: by B4 Submission Endpoint for mricon@gmail.com/default with auth_id=10
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Another completely fake series to test b4 endpoint sending. Please
ignore it -- it's a random set of patches that exists elsewhere.

Signed-off-by: Konstantin Ryabitsev <konstantin@linuxfoundation.org>
---
Changes in v11:
- Change commit author for testing reasons
- Link to v10: https://lore.kernel.org/r/20220825-test-endpoint-send-2-v10-0-bcba79986f75@linuxfoundation.org

Changes in v10:
- No changes, just junk.
- Link to v9: https://lore.kernel.org/r/20220825-test-endpoint-send-2-v9-0-b88029795c86@linuxfoundation.org

Changes in v9:
- No changes, just junk.
- Link to v8: https://lore.kernel.org/r/20220907130327.139757-1-jpanis@baylibre.com

Changes in v8:
- No changes, just junk.
- Link to v7: https://lore.kernel.org/r/20220825-test-endpoint-send-2-v7-0-cb9adabcb8df@linuxfoundation.org

Changes in v7:
- No changes, just junk
- Link to v6: https://lore.kernel.org/r/20220825-test-endpoint-send-2-v6-0-897ea7d26b87@linuxfoundation.org

Changes in v6:
- No changes, just junk.
- Link to v5: https://lore.kernel.org/r/20220825-test-endpoint-send-2-v5-0-9473e5c87f1a@linuxfoundation.org

Changes in v5:
- No changes, just junk.
- Link to v4: https://lore.kernel.org/r/20220825-test-endpoint-send-2-v4-0-30ef563fc249@linuxfoundation.org

Changes in v4:
- Rebased on v6.0-rc3
- Link to v3: https://lore.kernel.org/r/20220825-test-endpoint-send-2-v3-0-6e3357d699cd@linuxfoundation.org

Changes in v2:
- No changes
- Link to v1: https://lore.kernel.org/r/20220825-test-endpoint-send-2-v1-0-e732ebcaa48a@linuxfoundation.org

---
Clément Péron (1):
      arm64: defconfig: Enable devfreq cooling device

Konstantin Ryàbitsev (1):
      Junk babootich

 Makefile                     | 2 +-
 arch/arm64/configs/defconfig | 1 +
 2 files changed, 2 insertions(+), 1 deletion(-)
---
base-commit: b90cb1053190353cc30f0fef0ef1f378ccc063c5
change-id: 20220825-test-endpoint-send-2-c923fec10d0b

Best regards,
-- 
Konstantin Ryàbitsev <mricon@gmail.com>