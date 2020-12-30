#!/usr/bin/env sh
#
# DYNDNS2 like wrapper for DNS based domain validation
#
# Author: Sebastian Gmeiner
# https://github.com/BastiG/acme-sh-dyndns2
#
# DYNDNS2 like API that supports TXT record creation
# https://github.com/BastiG/dyndns-pdns
#
# In order to support multi-tenancy a special environment variable can be used:
# DYNDNS2_ENV - defaults to "DEFAULT"
#
# Pass credentials before "acme.sh --issue --dns dns_dyndns2 ..."
# export DYNDNS2_URL=API enpoint
# export DYNDNS2_Username=API user
# export DYNDNS2_Password=API password

########  Public functions #####################

# Usage:   add  Full-Domain Challenge-Code
# Example: add  "_acme-challenge.www.domain.com"   "Challenge-Code"
# Add a TXT record for domain validation
# Expects exported variables:
# - DYNDNS2_URL : the DYNDNS2 Enpoint
# - DYNDNS2_Username : the API user
# - DYNDNS2_Password : the API password
# - DYNDNS2_ENV : the value of ENV or "DEFAULT" if not specified
dns_dyndns2_add() {
  _debug "DynDNS 2 Update : add TXT record"
  fulldomain=$1
  txtvalue=$2

  DYNDNS2_ENV="${DYNDNS2_ENV:-$(_readdomainconf DYNDNS2_Env)}"
  [ -z "${DYNDNS2_ENV}" ] && DYNDNS2_ENV=DEFAULT

  DYNDNS2_URL_VAR="DYNDNS2_${DYNDNS2_ENV}_URL"
  DYNDNS2_Username_VAR="DYNDNS2_${DYNDNS2_ENV}_Username"
  DYNDNS2_Password_VAR="DYNDNS2_${DYNDNS2_ENV}_Password"

  DYNDNS2_URL="${DYNDNS2_URL:-$(_readaccountconf_mutable ${DYNDNS2_URL_VAR})}"
  DYNDNS2_Username="${DYNDNS2_Username:-$(_readaccountconf_mutable ${DYNDNS2_Username_VAR})}"
  DYNDNS2_Password="${DYNDNS2_Password:-$(_readaccountconf_mutable ${DYNDNS2_Password_VAR})}"
  if [ -z "${DYNDNS2_URL}" ] || [ -z "${DYNDNS2_Username}" ] || [ -z "${DYNDNS2_Password}" ]; then
    DYNDNS2_URL=""
    DYNDNS2_Username=""
    DYNDNS2_Password=""
    _err "Please export DYNDNS2_URL, DYNDNS2_Username and DYNDNS2_Password and try again."
    return 1
  fi

  # save the credentials to the account conf file.
  _saveaccountconf_mutable ${DYNDNS2_URL_VAR} "${DYNDNS2_URL}"
  _saveaccountconf_mutable ${DYNDNS2_Username_VAR} "${DYNDNS2_Username}"
  _saveaccountconf_mutable ${DYNDNS2_Password_VAR} "${DYNDNS2_Password}"

  # save the environment to the domain conf file.
  _savedomainconf "DYNDNS2_Env" "${DYNDNS2_ENV}"

  if _dyndns2_api "${DYNDNS2_URL}" "${DYNDNS2_Username}" "${DYNDNS2_Password}" "${fulldomain}" "${txtvalue}"; then
    _debug "Added, OK"
    return 0
  fi
  _err "Add TXT record error."
  return 1
}

# Usage:   rm  Full-Domain Challenge-Code
# Example: rm  "_acme-challenge.www.domain.com"   "Challenge-Code"
# Remove the TXT record after validation
dns_dyndns2_rm() {
  _debug "DynDNS 2 Update : remove TXT record"
  fulldomain=$1
  txtvalue=$2

  DYNDNS2_ENV="$(_readdomainconf DYNDNS2_Env)"

  # load the credentials from the account conf file.
  DYNDNS2_URL="$(_readaccountconf_mutable DYNDNS2_${DYNDNS2_ENV}_URL)"
  DYNDNS2_Username="$(_readaccountconf_mutable DYNDNS2_${DYNDNS2_ENV}_Username)"
  DYNDNS2_Password="$(_readaccountconf_mutable DYNDNS2_${DYNDNS2_ENV}_Password)"

  if [ -z "${DYNDNS2_URL}" ] || [ -z "${DYNDNS2_Username}" ] || [ -z "${DYNDNS2_Password}" ]; then
    _err "Cannot remove TXT record, settings not found."
    return 1
  fi

  if _dyndns2_api "${DYNDNS2_URL}" "${DYNDNS2_Username}" "${DYNDNS2_Password}" "${fulldomain}" ""; then
    _debug "Removed, OK"
    return 0
  fi
  _err "Removed TXT record error."
  return 1
}

####################  Private functions ##################################

# Usage:   _dyndns2_api  URL  Username  Password  Full-Domain  TXT-Record
# Example: _dyndns2_api  "https://myhost.com/dyn/update"  "myuser"  "mypassword"  "_acme-challenge.www.domain.com"  "Challenge-code"
# Make a REST call towards DYNDNS2 API. Adds the given TXT record to the DNS zone.
# Passing an empty TXT record causes existing Records to be deleted for the given domain.
_dyndns2_api() {
  DYNDNS2_URL=$1
  DYNDNS2_Username=$2
  DYNDNS2_Password=$3
  fulldomain=$4
  txtvalue=$5

  DYNDNS_CREDENTIALS="$(printf "%s" "${DYNDNS2_Username}:${DYNDNS2_Password}" | _base64)"
  export _H1="Authorization: Basic ${DYNDNS_CREDENTIALS}"

  response=$(_get "${DYNDNS2_URL}?hostname=${fulldomain}&txt=${txtvalue}")

  if [ "${response}" == "good" ] || [ "${response}" == "nochg" ]; then
    _debug2 response "Request was successful"
    _debug2 response "${response}"
    return 0
  else
    _err "Failed to update TXT record"
    [ "${response}" == "911" ] && _err "Server failed"
    [ "${response}" == "badauth" ] && _err "Authentication failed"
    [ "${response}" == "nohost" ] && _err "Domain not found or user may not alter zone"
    [ "${response}" == "numhosts" ] && _err "Too many hostnames in request"
    [ "${response}" == "dnserr" ] && _err "DNS backend API failed"

    _debug2 response "${response}"
    return 1
  fi

}
