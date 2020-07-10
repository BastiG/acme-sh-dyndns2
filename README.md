# How to use DYNDNS2

You need authorized access to a DYNDNS2 like service that supports setting TXT records. See [[1](#references)] for an example implementation as a PHP wrapper around PowerDNS API.

## 1. Installation

Copy `dns_dyndns2.sh` to a place where `acme.sh` can find it, I recommend `${ACME_HOME}/dnsapi/`.

## 2. Environments and endpoint information

You may define an environment, if you don't then the environment name will be `DEFAULT`.
```bash
export DYNDNS2_ENV=Database
```
If you deploy only one tenant (i.e. one user which will be able to manage all the hostnames on this particular machine) then you don't have to think about environments. Otherwise think of an environment as a way to group service endpoint and credentials in your account configuration. In this case we want this particular environment to manage all certificates for our databases.

If you already issued certificates for this a particular environment and the service endpoint and credentials didn't change, then chances are that you don't have to specify all those details again.

Otherwise you'll need to make them known first.
```bash
export DYNDNS2_URL=https://mydynhost.com/dyn/update.php
export DYNDNS2_Username=dyn-db-user
export DYNDNS2_Password=super53cr3t
```

## 3. Issue a certificate

Now you may issue the certificate:
```bash
acme.sh --issue --dns dns_dyndns2 -d example.com -d www.example.com
```

That's it. `DYNDNS2_URL`, `DYNDNS2_Username` and `DYNDNS2_Password` for the environment will be saved in `${ACME_HOME}/account.conf`. The pointer to the environment will be persisted in the domain config `${ACME_HOME}/example.com/example.com.conf` so it can be retrieved automatically when, e.g. renewing the certificate.

## References

[1] https://github.com/BastiG/dyndns-pdns
