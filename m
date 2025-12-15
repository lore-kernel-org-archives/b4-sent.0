From: David Heidelberg <david@ixit.cz>
Subject: [PATCH 0/4] Input: small nitpick fixes
Date: Mon, 15 Dec 2025 15:30:00 +0100
Message-Id: <20251215-fts-fixes-v1-0-8c1e3a63ebf1@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGgbQGkC/x2KOwqAMAxAr1IyG7ApDvUq4iA21SxVGhGheHeD4
 /s0UK7CCqNrUPkWlaMY+M7Bui9lY5RkDNTT4MkT5ksxy8OKwVTIiSOlCPaflf9g+zS/7wfDWL/
 wWwAAAA==
X-Change-ID: 20251212-fts-fixes-30253fde92d9
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Petr Hodina <petr.hodina@protonmail.com>, 
 Javier Martinez Canillas <javier@osg.samsung.com>, 
 Rob Herring <robh@kernel.org>, Andi Shyti <andi@etezian.org>
Cc: linux-input@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=687; i=david@ixit.cz;
 h=from:subject:message-id; bh=AwEDboNk5GmPqrs+ygIr6oF3UxdqLcCX4eLfPid2KXw=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpQBtraKyNehUYf6Zq6STWquVGzPauk3f3hyPmo
 SDg/syWgFuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaUAbawAKCRBgAj/E00kg
 cnymD/4+NtvqTd1F7d46ZcugHEDVrc8ViX33x3uIbtImJbzqS1A+MAec4i6/CM31tn4plgGWqWy
 6EypuPlpKe3sXz0yXKC6JeGjQA9mQiuKldrE1AyJSOI2wN+YlY+j1mjfwSETttukIHytCTV0nbf
 irO7tc+AFrOzqBS84eAj9ndDdQp7LCXjSBznGgnCLJKzREM00nrKhlZMxgI7sFbDD3yTjXNPce1
 M+XR7AYGoHD5B6hNRAUDEbXY/7+BFRCkvgEozGB+A4uc7yqaPDU1ILb56vfj1IavErElxFWq4pt
 j73h/x7YHjrM3RsZAjAMaEpAHp162W5xOCfYzVmcW0Ldch+Cd+3pxGYsFayjfqq7V1AukSQy94n
 1wgsvafywp/tx8HPPNQf/GWLhhOhUFzJR9s3pA0HQrDcZte6mAI+m1mw3GMg4mAyR3Y0rkZHqv0
 prczUCdbQbTjBsGu+bhigFIMlCnwBm96sYKm8Dipxnfro++8FCv/RWfuj2CUOa0kJuwylkmT9RG
 HOlLXX8pcQdXOpZPwa8vGZoZvZcox/6BETTxeCARd9R1txymFGXBY0dPXvcZ8q6KF/0pwKwHKWE
 uy8fNM5yr9XrYOCMLDOznJL8huvL/ZiRudqnhXqaVPIdmDyIf5iCm14FRfejA/MSEwKg7FKEL2h
 sVYg2BC42MPHhNw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Feel free to ignore the last patch, if you want to wait for FTS5
support.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
David Heidelberg (1):
      Input: stmfts - correct wording for the warning message

Petr Hodina (3):
      Input: stmfts - Make comments correct
      Input: stmfts - use sysfs_emit() instead of sprintf()
      Input: stmfts - use client to make future code cleaner

 drivers/input/touchscreen/stmfts.c | 24 +++++++++++-------------
 1 file changed, 11 insertions(+), 13 deletions(-)
---
base-commit: 4a5663c04bb679631985a15efab774da58c37815
change-id: 20251212-fts-fixes-30253fde92d9

Best regards,
-- 
David Heidelberg <david@ixit.cz>

