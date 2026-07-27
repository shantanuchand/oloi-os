# Oloi OS Location Intelligence — Working Notes

**Status:** Canonical working record  
**Last updated:** 2026-07-27  
**Scope:** Location modelling, routing, and journey intelligence for Oloi OS, with Kenya as the first operating context.

## Purpose and record-keeping rule

Oloi OS needs a location model that represents how a journey actually works, not just where places sit on a map. A destination, park, property, gate, airstrip, border post, and road junction can each play a different role in planning even when they are geographically close.

This file is the canonical working record for Location Intelligence architecture discussions. Future decisions should update this document in the same repository. Material changes should preserve the distinction between:

- **Decided:** accepted modelling or routing behaviour.
- **Proposed:** a direction that still needs implementation or product validation.
- **Open:** an unresolved question.

## Core decision: model a travel graph, not a flat place list

**Decided.** Represent the travel domain as a directed, multi-modal graph:

- **Nodes** are meaningful places or transition points.
- **Edges** are traversable travel segments.
- **Routes** are ordered paths through nodes and edges.
- **Journeys** are user-facing plans assembled from routes, timings, constraints, and stops.

Coordinates remain essential, but straight-line distance is not a sufficient routing model. Route feasibility and travel time depend on access rules, gate choice, border operations, schedules, road conditions, vehicle type, season, and time of day.

A single physical feature may expose multiple logical nodes. For example, a border crossing has an approach node on each side plus a crossing transition; an airport may have a public landside node and a scheduled-flight transition; and a park gate connects the public road network to a restricted internal network.

## Node taxonomy

### Destinations and stays

Destinations are the places a traveller understands as trip stops: towns, conservancies, parks, regions, camps, lodges, hotels, homes, and points of interest. Accommodation properties attach to the travel graph through an access node rather than relying only on their latitude and longitude.

### Park gates

**Decided.** Park gates are first-class access-control nodes, not ordinary points of interest.

A park or reserve may have several gates, and the selected gate can materially change the route, permitted hours, fees, vehicle requirements, and journey time. The model should support:

- the protected area served by the gate;
- entry, exit, or bidirectional use;
- opening hours and last-entry guidance;
- resident/non-resident or vehicle restrictions where relevant;
- seasonal or temporary closure state;
- public-road approach edges;
- internal park-road edges;
- source, confidence, and last verification time.

Routing must not treat two nearby gates as interchangeable. A route into a protected area must explicitly pass through a usable gate unless an authorized air access path applies.

### Border crossings

**Decided.** Border crossings are first-class international transition nodes.

A border path must model more than road geometry. It should allow for:

- countries joined and direction of travel;
- immigration, customs, visa, vehicle, insurance, and permit constraints;
- operating hours;
- expected processing time and uncertainty;
- pedestrian, private vehicle, commercial vehicle, rail, or other supported modes;
- temporary closure or restriction state;
- separate approach, processing, and onward-travel segments where useful.

Crossing time is a route cost with variance, not a fixed zero-duration connection. Oloi should avoid presenting an international route as feasible merely because a road crosses a boundary on the base map.

### Transport nodes

**Decided.** Airports, airstrips, railway stations, bus or coach terminals, ports, ferry landings, and other transfer points are transport nodes.

Transport nodes connect different travel modes and therefore need transfer semantics:

- modes served;
- scheduled versus on-demand service;
- check-in, security, boarding, baggage, and transfer buffers;
- operating hours and daylight-only constraints where applicable;
- private charter or operator restrictions;
- surface access and onward-transfer edges.

An airport or station is not itself a complete connection. The graph should distinguish arrival and departure processes and the surface leg between the transport node and the actual stay or destination.

### Gateway nodes

**Decided.** A gateway is a role applied to a node that mediates practical access to a destination or region. It is not necessarily a separate physical-place type.

Examples include:

- a town used to provision or stage before a remote area;
- an airport normally used to reach a safari circuit;
- a park gate providing access to a lodge cluster;
- a junction where travellers leave a trunk road for a destination approach;
- a border post used to enter a cross-border circuit.

Gateway relationships should be explicit, directional, and scoped by mode. One destination may have multiple gateways, ranked by traveller profile, season, cost, or route origin. A gateway can also be a destination in its own right.

### Junctions, waypoints, and service nodes

Road junctions and route waypoints should be stored when they change a routing decision, disambiguate an approach, or provide operational value. Fuel, charging, food, medical, rest, recovery, and safe-stop locations are service nodes and can be included according to journey risk and traveller needs.

## Travel corridors

**Decided.** A travel corridor is a named, reusable sequence or family of edges that captures a recognized movement pattern. It is a routing concept, not a single polyline.

Corridors may represent:

- a trunk-road connection between major gateways;
- a safari circuit linking parks, conservancies, gates, airstrips, and stays;
- an urban transfer pattern between an airport and a city node;
- a cross-border route;
- a coastal, highland, western, northern, or other regional movement spine.

A corridor can have variants by direction, season, vehicle class, or transport mode. Corridors should carry operational knowledge such as normal stopping points, known constraints, risk flags, typical duration bands, and the sources used to verify them.

Corridors guide candidate-route generation and explanation, but do not override closed edges or current constraints.

## Kenya-first routing concepts

**Decided.** Kenya routing should be grounded in operational travel patterns rather than generic shortest-path output.

### National and regional gateways

The initial model should be able to express major gateway roles such as:

- Nairobi as the primary national and multi-circuit gateway;
- JKIA for international and domestic air connections;
- Wilson Airport for many safari and regional air movements;
- Mombasa and the coast as a coastal air, rail, road, and port gateway;
- Nanyuki and other staging towns as gateways to Laikipia and northern circuits;
- Kisumu as a western Kenya and Lake Victoria gateway;
- park-adjacent towns, gates, and airstrips as last-mile gateways.

These are role examples, not a closed or permanently ranked list. Gateway suitability depends on the actual origin, destination, mode, schedule, and operating context.

### Protected-area access

Kenya journey planning must route to the correct named gate or authorized airstrip before routing inside a park, reserve, or conservancy. Gate hours, internal-road conditions, conservancy permissions, and daylight constraints can make a geometrically short route invalid.

Properties associated with a protected area must retain their real access path. Marketing geography, such as being described as “in” or “near” a park, must not substitute for the actual gate, conservancy, or road access relationship.

### Safari and remote-road timing

Travel times should be stored and communicated as ranges when uncertainty is meaningful. The cost model should account for:

- paved versus unpaved surface;
- wet or dry season and recent weather;
- daylight-only or recommended-daylight travel;
- traffic near major urban areas;
- road quality and construction;
- vehicle capability, including 4x4 requirements;
- wildlife-area speed limits and game-drive pace;
- fuel range and recovery options;
- scheduled flight, charter, rail, ferry, or transfer timing.

Do not infer road time from distance alone. A short final approach can dominate the journey time.

### Multi-modal itineraries

Common Kenya itineraries may combine international air, domestic scheduled or charter flights, road transfers, rail, ferry, and internal game-drive segments. Each mode change should be represented as a transfer with an explicit buffer and its own uncertainty.

Examples the graph must support include:

- international arrival → Nairobi transfer → Wilson departure → safari airstrip → lodge transfer;
- Nairobi → trunk road corridor → staging town → park gate → internal park road → camp;
- Nairobi → rail, air, or road to the coast → local transfer → property;
- Kenya road circuit → border processing → onward regional corridor.

### Cross-border continuity

For routes connecting Kenya with neighbouring countries, the domestic road to the border, the crossing process, and the foreign onward route are distinct segments. Eligibility and timing checks belong at the border transition. Oloi should surface uncertainty and documentary requirements rather than silently treating the boundary as another road vertex.

## Edge and route semantics

**Decided.** Edges are directed and may coexist between the same nodes for different modes, operators, access classes, or seasonal variants.

Minimum edge concepts:

- `from_node` and `to_node`;
- mode and service or operator where applicable;
- distance and duration range;
- schedule or frequency where applicable;
- access and vehicle constraints;
- validity dates, seasonality, and closure state;
- confidence, evidence source, and last verification time;
- geometry or reference to a routing-provider path;
- risk and traveller-advisory annotations.

Route selection should be constraint-first, then optimize among feasible candidates:

1. Exclude closed, unauthorized, mode-incompatible, or time-infeasible edges.
2. Enforce required transitions such as gates, borders, and transport transfers.
3. Apply traveller and vehicle constraints.
4. Rank feasible paths using time, reliability, cost, comfort, risk, and traveller preference.
5. Explain the selected gateways and consequential assumptions.

The “best” route is contextual; it is not always the shortest or fastest route.

## Data quality and provenance

**Decided.** Operational location facts require provenance and freshness metadata. Each consequential fact should support:

- source type and source reference;
- observed, published, or verified date;
- confidence level;
- who or what verified it;
- validity window where known;
- conflict notes when sources disagree.

User-facing plans should distinguish verified facts from estimates and assumptions. Time-sensitive facts—closures, schedules, gate hours, border operations, and road conditions—must be revalidated close to travel.

## Suggested implementation shape

**Proposed.** Start with normalized entities that can evolve without collapsing roles into one table:

- `locations` — identity, name, coordinates, geography, and broad physical type;
- `location_roles` — gateway, destination, service, staging, or other contextual roles;
- `access_points` — gates, entrances, terminals, border facilities, and their parent place;
- `transport_services` — scheduled or on-demand movements between transport nodes;
- `travel_edges` — directed traversable segments with constraints and cost ranges;
- `corridors` and `corridor_edges` — named reusable route structures;
- `access_rules` — hours, eligibility, permits, modes, and vehicle constraints;
- `travel_time_observations` — source observations used to calibrate duration ranges;
- `operational_events` — temporary closures, disruptions, and advisories;
- `journey_routes` and `journey_legs` — selected, explainable user-facing plans.

Prefer stable internal identifiers and alternate-name support. Names alone are unsafe identifiers, particularly where spelling varies or a gate, airstrip, town, conservancy, and property share similar names.

## Product behaviour implied by the model

Oloi should:

- ask for or infer the traveller, date and time, mode, party, and vehicle context needed to test feasibility;
- state the gate, border, transport node, and gateway assumptions that materially shape a route;
- expose duration ranges and confidence rather than false precision;
- show why a plausible-looking shortcut is unavailable;
- keep route geometry separate from curated operational knowledge;
- allow a human operator to override, verify, or annotate routing facts;
- preserve the evidence behind important recommendations.

## Open questions

- Which routing and map providers will supply base geometry, traffic, and road attributes?
- Which Kenya corridors and destination clusters should be curated first for Phase 1?
- What freshness thresholds apply to each operational fact type?
- Which sources are authoritative enough to auto-publish, and which require human review?
- How will access fees, permits, visas, and operator-specific restrictions integrate with journey costing?
- What offline or low-connectivity behaviour is required for field operations?
- How should confidence and uncertainty be displayed to travellers versus internal operators?
- Which location roles and constraints must be configurable by market as Oloi expands beyond Kenya?

## Near-term architecture actions

1. Turn the node, edge, corridor, access-rule, and provenance concepts into an initial schema.
2. Build a small Kenya reference graph containing representative urban gateways, transport nodes, park gates, a border transition, a staging town, and a remote property approach.
3. Import travel-time observations without flattening ranges into one universal duration.
4. Test constraint-first routing against road-only, fly-in safari, park-entry, coastal, and cross-border journeys.
5. Add a review workflow for time-sensitive operational facts.
6. Update this file whenever an architecture discussion accepts, revises, or retires a Location Intelligence decision.
