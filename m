From: Joel Granados <joel.granados@kernel.org>
Subject: [PATCH 0/3] scripts: Add a root dir in archve-source.sh
Date: Tue, 08 Apr 2025 22:14:45 +0200
Message-Id: <20250408-jag-sysctl-v1-0-3f4f38b751be@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALWD9WcC/23MSw7CIBSF4a00dyyGR6m1I/dhOqB4oWgDBhpi0
 7B3sWOH/0nOt0PC6DDB0OwQMbvkgq/BTg3oWXmLxD1qA6dc0pb25KksSVvS60JEp4Wcrh3VvId
 6eEc07nNg97H27NIa4nbYmf3Wv0xmhBIjdasmJfBizO2F0eNyDtHCWEr5Aql7VZSlAAAA
X-Change-ID: 20250408-jag-sysctl-36c35b960c28
To: =?utf-8?q?Alex_Benn=C3=A9e?= <alex.bennee@linaro.org>, 
 =?utf-8?q?Philippe_Mathieu-Daud=C3=A9?= <philmd@linaro.org>, 
 Thomas Huth <thuth@redhat.com>, 
 Wainer dos Santos Moschetta <wainersm@redhat.com>
Cc: qemu-devel@nongnu.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1009;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=wsX5JeCeUenZtAXorAHzLnlv/QiMaURnQ+d3eE0sd4A=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGf1g7rt1DLW60zvHojJfCFHedC4h+6vXsG47
 +2ArW2O5vrD/4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJn9YO6AAoJELqXzVK3
 lkFPd5IL/2wml2hU6QsJcLVJNVG0qjPr2aYVKFphwndj2tG3tZBa2n/lk24D/FKZgWofIPFj7Bt
 85u256DZOeNOvicwvPi3XbnrVaV8GodEh4yhuqIcsl8fGDlTK5H3ZjNPKPO8czqiAl+Zs9QvctV
 FfSze/mAENCidfyvELIYb/bhRqjLWufLBlL0ssfwYzCCmbQZCtvc1VgyfiOUvxzNnQoWNhWMMrn
 A4qfGgZsdoKBYhkjeEPsz8aeZq110RFZ1Y6snUV5THtoz2POG3weEqofWuiTvCk34hBEj9GpAT1
 PDfRG0uQl/IpXMTiLySWE5KrBblUylOyHx6qW2+myZ8dk7czIbOwvKTHmYADIHVvXjbYLw4VpSK
 eQXxs33Es3IzfvZ/NfFtCyXTeA3+IpFJa1AUKGMd9ntvqBbgMS60rUmdvVem+x5VNq7HXgWh1SS
 isLpeJJnDr1Che+eO+r+rxZKkJHP+s/2q1lD2Z7W4+SUsy0okCP42c2u14UEa/g8aDqcV8kdBi7
 s8=
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

PS: Had initialy missed adding qemu-devel to CC. Appologies if you
    received this twice.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
--

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

