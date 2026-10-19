# @summary Variables for /etc/default/unifi, keyed by shell variable name.
type Unifi::Environment = Hash[Pattern[/\A[A-Za-z_][A-Za-z0-9_]*\z/], Variant[String, Integer, Boolean]]
