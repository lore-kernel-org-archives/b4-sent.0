From: Bernd Schubert <bernd@bsbernd.com>
Date: Wed, 30 Sep 2026 15:11:09 +0200
Subject: [PATCH v3 15/15] move fuse_service_priv.h from include/ to lib/
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-mount-service-bound-open-v3-15-e26c5e4eca4c@bsbernd.com>
References: <20260930-mount-service-bound-open-v3-0-e26c5e4eca4c@bsbernd.com>
In-Reply-To: <20260930-mount-service-bound-open-v3-0-e26c5e4eca4c@bsbernd.com>
To: fuse-devel@lists.linux.dev
Cc: "Darrick J. Wong" <djwong@kernel.org>, neal@gompa.dev, 
 Bernd Schubert <bernd@bsbernd.com>
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=463; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=lMeyN6pYndX7o4W14bp1z1NpA5fft5V2+Wv9PrgunkE=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLL2cuVfkss0jlRJX22TwnOJddLtS4XsItf3Cypr8AT4H
 tU/ufpxRykLgxgHg6yYIkuXxB7bKf/4ZNW+rr8OM4eVCWQIAxenAEykU46RYdGd/JrbGq2+z/z6
 a15f+bu69pddvSaj3/yaPw25WjrbzjAyNPnd1ta5rau/+RFP4fLJc7X6vZ9s/8fCscDHkXv3w0+
 S7AA=
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

That had slipped through during review, libfuse convention is to
have include/ reserved for headers included by applications.

Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
 {include => lib}/fuse_service_priv.h | 0
 1 file changed, 0 insertions(+), 0 deletions(-)

diff --git a/include/fuse_service_priv.h b/lib/fuse_service_priv.h
similarity index 100%
rename from include/fuse_service_priv.h
rename to lib/fuse_service_priv.h

-- 
2.53.0

