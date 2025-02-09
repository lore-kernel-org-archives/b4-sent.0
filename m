From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Subject: [PATCH v3 0/2] media: i2c: dw9719: Add device tree bindings for
 the VCM
Date: Sun, 09 Feb 2025 22:51:56 +0100
Message-Id: <20250209-dw9761dts-v3-0-14d3f00f0585@apitzsch.eu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAHwjqWcC/42QzW7DIBAGX8XiXCxYbH58yntUOWBYBw6OUyBO2
 sjvXuKmUo89joRmh+9BMqaImQzNgyRcY47LuYJ4a4gL9nxCGn1lAgx6BkxSfzNKcl8ydd455hT
 vRm5JfX9JOMX77no/Vp7SMtMSEtpfQ8c564EJ2esWjBKKcho8nhb0eEjogy2tW+aXLOHHtfaUH
 yOZMWe79wzN/13Dyp+60WakFedYhkZPUoJxjNVyIzwIyUF23AnJFCrda27QKDuS5y9CzGVJn/t
 AK+wlry30ny1WqOcdE3rSFqbRdAd7ieUru9DilRy3bfsG+6/qdmoBAAA=
X-Change-ID: 20250206-dw9761dts-cdcc0c714b1a
To: Daniel Scally <djrscally@gmail.com>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, devicetree@vger.kernel.org
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739137936; l=1009;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=uLOKFkONbrwKQL0GVTL+RBqZQj2F5LXwTUf/BvmTzYQ=;
 b=IiP+hQdUKjqTHKOqSuxW1WjW+yGfW8hmUydgX6oR5AURPoKBy3XBShxsYFyalzKIFzRVTHQDS
 TolWnwqv4ZYB5rNwKTkTe4pScljy2iThcbsn3Uoipz2JDLP5bH9RXHg
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the Dongwoon DW9719 and DW9761 dt-bindings and add the related
of_match table.

Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
Changes in v3:
- Add patch to document devicetree bindings
- Add "i2c:" to the subject of the 'Add of_match table' commit message
- Link to v2: https://lore.kernel.org/r/20250208-dw9761dts-v2-1-c038f8a2fb94@apitzsch.eu

Note, there was no v1.

---
André Apitzsch (2):
      dt-bindings: media: i2c: Add DW9719 and DW9761 VCM
      media: i2c: dw9719: Add of_match table

 .../bindings/media/i2c/dongwoon,dw9719.yaml        | 45 ++++++++++++++++++++++
 drivers/media/i2c/dw9719.c                         |  8 ++++
 2 files changed, 53 insertions(+)
---
base-commit: 8f6629c004b193d23612641c3607e785819e97ab
change-id: 20250206-dw9761dts-cdcc0c714b1a
prerequisite-message-id: 20241105203658.29737-1-hdegoede@redhat.com:v1
prerequisite-patch-id: b0a57666bd20b97291583c3052065dc314a37e79

Best regards,
-- 
André Apitzsch <git@apitzsch.eu>

