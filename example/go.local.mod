module github.com/mechiru/authorized-buyers-proto/example

go 1.14

replace (
	github.com/mechiru/authorized-buyers-proto/networkbid => ../networkbid
	github.com/mechiru/authorized-buyers-proto/openrtbadx => ../openrtbadx
)

require (
	github.com/mechiru/authorized-buyers-proto/networkbid v0.0.0-00010101000000-000000000000
	github.com/mechiru/authorized-buyers-proto/openrtbadx v0.0.0-00010101000000-000000000000
)
