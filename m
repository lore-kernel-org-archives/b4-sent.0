From: Joel Granados <joel.granados@kernel.org>
Subject: [PATCH 0/3] scripts: Add a root dir in archve-source.sh
Date: Tue, 08 Apr 2025 10:02:40 +0200
Message-Id: <20250408-jag-sysctl-v1-0-f5c4aba3e7ff@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIACDY9GcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDEwML3azEdN3iyuLkkhxdY7NkY9MkSzODZCMLJaCGgqLUtMwKsGHRsbW
 1AH/6JYtcAAAA
X-Change-ID: 20250408-jag-sysctl-36c35b960c28
To: =?utf-8?q?Alex_Benn=C3=A9e?= <alex.bennee@linaro.org>, 
 =?utf-8?q?Philippe_Mathieu-Daud=C3=A9?= <philmd@linaro.org>, 
 Thomas Huth <thuth@redhat.com>, 
 Wainer dos Santos Moschetta <wainersm@redhat.com>
Cc: Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1102;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=oY+EUFqeVjtuXIV93ArVpYOykcvAmtvMN6MXR8UDh9s=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGf02Dl4ECwLHPmGZWeuRkJhmGeo4NOaRbb8D
 fwjOvNiWlhxX4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJn9Ng5AAoJELqXzVK3
 lkFPmlYMAIc3SaC1Ht/sdGqX1JZ6MeUPKNAChjmS21VWoDa0HdG7RcAzgGDJuoNOMYXXTRB8ajd
 prS3xVnGwbLrJ033CZwAZ5cqiyGa184Wnq0yhxjsH0+SQvBc/ACU0EeEFVkC2AESmOdTWF28j7+
 DnApN4whlDghAOsFtE4xaAKJes4XMcL1PX0i2USjOa9PaN2YC6Czypg3kNXHIQ5dToscpYimA1O
 S+ba4ylpbHXwU22DGfrITD5Kk0q8rRwFOjV5OgYvZ8vSqatgFHnL67uevKAbzsTOakSaBi2GhJc
 MGyrGeFdCEA97FfwaR+c9YFlQqOEU4a46uZBzIBqDJSgceRdaj9m8mO9CLWyo16lVVzo5CGGj38
 3iLZ2jhERoZH2mvS4yLh1dFL016v9S0pPaVYqZEBGuouWcvW8pXFM2WHFwsUIDzLPUGF/Ll3DjN
 SMkjzS4MU9s2TQS120KPveSn5Ja4fxX/M7qnx6WeEAsjAmenZYQAfIUEbLaeyproT0jyXuUYnX6
 bs=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When creating an archive source to use in a nix overlay, it is necessary
that all files are appended to the tar.gz file under a root dir. This
series adds a argument (--dir) that will create a root directory and
append all files under it.

The series does not change the default behavior where all files are
added to the tar.gz root.

Comments are greatly appreciated.

To: "Alex Bennée" <alex.bennee@linaro.org>
To: "Philippe Mathieu-Daudé" <philmd@linaro.org>
To: Thomas Huth <thuth@redhat.com>
To: Wainer dos Santos Moschetta <wainersm@redhat.com>

--

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
Joel Granados (3):
      scripts: nixify archive-source.sh
      scripts: Add root dir to arguments
      scripts: Clarify doc messages in archive-source.sh

 scripts/archive-source.sh | 92 +++++++++++++++++++++++++++++++++++------------
 1 file changed, 69 insertions(+), 23 deletions(-)
---
base-commit: ea35a5082a5fe81ce8fd184b0e163cd7b08b7ff7
change-id: 20250408-jag-sysctl-36c35b960c28

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

