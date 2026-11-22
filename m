From: Eduardo Pereira Cruz <dreduardocruz@gmail.com>
Date: Sun, 22 Nov 2026 13:08:43 -0300
Subject: [PATCH 1/4] docs/translations/pt_BR: process: add
 maintainer-pgp-guide.rst (1/4)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261122-maintainer-pgp-guide-pt-br-v1-1-01ce5941c5c2@gmail.com>
References: <20261122-maintainer-pgp-guide-pt-br-v1-0-01ce5941c5c2@gmail.com>
In-Reply-To: <20261122-maintainer-pgp-guide-pt-br-v1-0-01ce5941c5c2@gmail.com>
To: linux-doc@vger.kernel.org
Cc: danielmaraboo@gmail.com, corbet@lwn.net, skhan@linuxfoundation.org, 
 rdunlap@infradead.org, Eduardo Pereira Cruz <dreduardocruz@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795363722; l=5954;
 i=dreduardocruz@gmail.com; s=20261119; h=from:subject:message-id;
 bh=EJlrJWgTSTNQ8VVVl0iv3PrJ05mnog12cuiU3VTLIX4=;
 b=cI7J4agvajgR8hVBUlHDZwoqI3+8wdMqRZRhrDOrMbjL0yZgJWwAWyypDesWYAJD35OTijzM4
 pTRjzMa/ZN1DJG/dF3COmSKSIPqM41B0rt19k3Ulx+I5w8YVlTtzQtp
X-Developer-Key: i=dreduardocruz@gmail.com; a=ed25519;
 pk=2dtL+BL/x70sROmAvlskv9dbjj274zlPkLBVu4gJJiA=
X-Endpoint-Received: by B4 Relay for dreduardocruz@gmail.com/20261119 with auth_id=1571
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Start the Brazilian Portuguese translation of the maintainer PGP guide:
the introduction, the role of PGP in kernel development, the recommended
GnuPG setup and the first part of key protection.

The translation follows the English original as last changed by commit
fdd100ee60a0 ("docs: process: use gender-neutral pronouns") and keeps
the cross-reference labels, the note and warning directives, and every
command and key listing verbatim.

Signed-off-by: Eduardo Pereira Cruz <dreduardocruz@gmail.com>
---
 .../pt_BR/process/maintainer-pgp-guide.rst         | 111 +++++++++++++++++++++
 1 file changed, 111 insertions(+)

diff --git a/Documentation/translations/pt_BR/process/maintainer-pgp-guide.rst b/Documentation/translations/pt_BR/process/maintainer-pgp-guide.rst
new file mode 100644
index 000000000000..a4ec5c5ef83b
--- /dev/null
+++ b/Documentation/translations/pt_BR/process/maintainer-pgp-guide.rst
@@ -0,0 +1,111 @@
+.. SPDX-License-Identifier: GPL-2.0
+
+.. _pgpguide:
+
+=======================================
+
+Guia de PGP para mantenedores do kernel
+=======================================
+
+:Author: Konstantin Ryabitsev <konstantin@linuxfoundation.org>
+
+Este documento é destinado aos desenvolvedores do kernel Linux e,
+especialmente, aos mantenedores de subsistema. Ele contém um subconjunto das
+informações discutidas no guia mais geral "`Protecting Code Integrity`_",
+publicado pela Linux Foundation. Leia aquele documento para uma discussão mais
+aprofundada sobre alguns dos tópicos mencionados neste guia.
+
+.. _`Protecting Code Integrity`: https://github.com/lfit/itpol/blob/master/protecting-code-integrity.md
+
+O papel do PGP no desenvolvimento do kernel Linux
+=================================================
+
+O PGP ajuda a garantir a integridade do código produzido pela comunidade de
+desenvolvimento do kernel Linux e, em menor grau, a estabelecer canais de
+comunicação confiáveis entre desenvolvedores por meio de troca de e-mails
+assinados com PGP.
+
+O código-fonte do kernel Linux está disponível em dois formatos principais:
+
+- Repositórios de código distribuídos (Git)
+- Instantâneos periódicos de versões (tarballs)
+
+Tanto os repositórios Git quanto os tarballs carregam assinaturas PGP dos
+desenvolvedores do kernel que criam as versões oficiais. Essas assinaturas
+oferecem uma garantia criptográfica de que as versões baixáveis
+disponibilizadas via kernel.org ou qualquer outro espelho são idênticas ao que
+esses desenvolvedores têm em suas estações de trabalho. Para isso:
+
+- Repositórios Git fornecem assinaturas PGP em todas as tags
+- tarballs fornecem assinaturas PGP destacadas junto com todos os downloads
+
+.. _devs_not_infra:
+
+Confiar nos desenvolvedores, não na infraestrutura
+--------------------------------------------------
+
+Desde o comprometimento dos sistemas centrais do kernel.org em 2011, o
+princípio operacional principal do projeto Kernel Archives tem sido assumir que
+qualquer parte da infraestrutura pode ser comprometida a qualquer momento. Por
+essa razão, os administradores tomaram medidas deliberadas para enfatizar que a
+confiança deve sempre ser depositada nos desenvolvedores e nunca na
+infraestrutura de hospedagem de código, independentemente de quão boas sejam as
+práticas de segurança desta última.
+
+O princípio orientador acima é a razão pela qual este guia é necessário.
+Queremos garantir que, ao depositar confiança nos desenvolvedores, não
+estejamos apenas transferindo a culpa por potenciais incidentes futuros de
+segurança para outra pessoa. O objetivo é fornecer um conjunto de diretrizes
+que os desenvolvedores possam usar para criar um ambiente de trabalho seguro e
+proteger as chaves PGP usadas para estabelecer a integridade do próprio kernel
+Linux.
+
+.. _pgp_tools:
+
+Ferramentas PGP
+===============
+
+Use GnuPG 2.4 ou mais recente
+-----------------------------
+
+Sua distro já deve ter o GnuPG instalado por padrão; você só precisa verificar
+se está usando uma versão razoavelmente recente. Para conferir, execute::
+
+    $ gpg --version | head -n1
+
+Se você tem a versão 2.4 ou superior, está tudo certo. Se tiver uma versão
+anterior, você está usando uma versão do GnuPG que não é mais mantida e alguns
+comandos deste guia podem não funcionar.
+
+Configure as opções do gpg-agent
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+O agente do GnuPG é uma ferramenta auxiliar que inicia automaticamente sempre
+que você usa o comando ``gpg`` e roda em segundo plano com o propósito de
+guardar em cache a passphrase da chave privada. Há duas opções que você deve
+conhecer para ajustar quando a passphrase deve expirar do cache:
+
+- ``default-cache-ttl`` (segundos): se você usar a mesma chave novamente antes
+  de o tempo de vida expirar, a contagem regressiva reinicia por outro período.
+  O padrão é 600 (10 minutos).
+- ``max-cache-ttl`` (segundos): independentemente de quão recentemente você usou
+  a chave desde a primeira entrada da passphrase, se a contagem do tempo de
+  vida máximo expirar, você terá de digitar a passphrase novamente. O padrão
+  é 30 minutos.
+
+Se você achar qualquer um desses padrões curto (ou longo) demais, pode editar
+o arquivo ``~/.gnupg/gpg-agent.conf`` para definir os seus próprios valores::
+
+    # set to 30 minutes for regular ttl, and 2 hours for max ttl
+    default-cache-ttl 1800
+    max-cache-ttl 7200
+
+.. note::
+
+    Não é mais necessário iniciar o gpg-agent manualmente no começo da sua
+    sessão de shell. Você pode querer verificar os seus arquivos rc para
+    remover qualquer coisa que tivesse para versões anteriores do GnuPG, pois
+    pode não estar mais fazendo a coisa certa.
+
+.. _protect_your_key:
+

-- 
2.53.0

