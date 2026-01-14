From: Jihan LIN <linjh22s@gmail.com>
Subject: [PATCH v2 0/2] gendwarfksyms: Document build dependencies
Date: Wed, 14 Jan 2026 19:47:43 +0800
Message-Id: <20260114-documents_gendwarfksyms-v2-0-297c98bd62c6@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAF+CZ2kC/3WNQQ7CIBQFr9L8tRhAa6kr72Eag/BpiQIGarVpu
 LvYxKXLmeTNWyBhtJjgWC0QcbLJBl+AbypQg/Q9EqsLA6f8QBmtiQ7q6dCP6dKj1y8ZzS3NLpH
 WCIF72UjNDZT1I6Kx77V87goPNo0hzuvRxL721xR/mxMjjNT8ykyrdkI19NQ7ae9bFRx0OecPF
 /L5zr4AAAA=
X-Change-ID: 20260105-documents_gendwarfksyms-9f88e4a7ad2f
To: Nathan Chancellor <nathan@kernel.org>, Nicolas Schier <nsc@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Miguel Ojeda <ojeda@kernel.org>, 
 Boqun Feng <boqun.feng@gmail.com>, Sami Tolvanen <samitolvanen@google.com>, 
 Masahiro Yamada <masahiroy@kernel.org>, Petr Pavlu <petr.pavlu@suse.com>
Cc: linux-modules@vger.kernel.org, linux-kbuild@vger.kernel.org, 
 linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jihan LIN <linjh22s@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768391298; l=1284;
 i=linjh22s@gmail.com; s=linjh22s_machine; h=from:subject:message-id;
 bh=42b1jPMRaZQMJsFTcdIPsgOH+T5OPHq2ZKwWlPwIz44=;
 b=OhZJJST3EqaB8evuw8uBs1/Mh0MwTtGN1AdtBslfMv4u2s/DuVo6soixm5q9t7N9lQDdQmtf9
 gnU8lXrczWABzmmL5EWYh3qHGm4lX5ghB3gimUgRYyMRPQM8nDZqA7C
X-Developer-Key: i=linjh22s@gmail.com; a=ed25519;
 pk=MnRQAVFy1t4tiGb8ce7ohJwrN2YFXd+dA7XmzR6GmUc=
X-Endpoint-Received: by B4 Relay for linjh22s@gmail.com/linjh22s_machine with auth_id=592
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

I found there is no documentation for build dependencies in gendwarfksyms
while digging into Rust drivers. Though Yuli added libdw-dev to the build
dependencies for packaging [1], it seems that there is no documentation
about it.

This series documents the build dependencies of gendwarfksyms, adds a few
examples for installing these dependencies on some distributions and
introduces indentation style cleanup as suggested.

[1]: https://lore.kernel.org/all/79C925DCE2E963FF+20250422104927.144252-1-wangyuli@uniontech.com/

Signed-off-by: Jihan LIN <linjh22s@gmail.com>
---
Changes in v2:
- Fix style for section 'Dependencies'.
- Introduce a new patch to clean up indentation in gendwarfksyms.rst.
- Link to v1: https://lore.kernel.org/r/20260108-documents_gendwarfksyms-v1-1-52b1f9c38c70@gmail.com

---
Jihan LIN (2):
      Documentation/kbuild: Document gendwarfksyms build dependencies
      Documentation/kbuild: gendwarfksyms: Style cleanup

 Documentation/kbuild/gendwarfksyms.rst | 123 +++++++++++++++++++--------------
 1 file changed, 73 insertions(+), 50 deletions(-)
---
base-commit: b71e635feefc852405b14620a7fc58c4c80c0f73
change-id: 20260105-documents_gendwarfksyms-9f88e4a7ad2f

Best regards,
-- 
Jihan LIN <linjh22s@gmail.com>

