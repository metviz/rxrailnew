**🚦 RXRail – Railway Proximity IntelAlert System**

**Stay Alert. Stay Safe.**

RXRail is a free, open-source mobile app that warns users when they’re approaching railroad tracks or crossings.
Built with safety, awareness, and real-world impact in mind, RXRail uses real-time GPS and open mapping data to help prevent accidents caused by distraction.

🌍 **Our Mission**

RXRail was inspired by a personal loss that became a call to action:
to prevent distracted-approach accidents at railroad crossings using smart technology and open data.

Our goal is simple:
**Turn awareness into safety — because one alert can save a life.**

⭐ **Key Features**

🚨 **Railway Proximity IntelAlert**

Real-time alerts when approaching railroad tracks or crossings, even when the app is running in the background.

📡 **Background Operation** (Ongoing Optimization ...) 

RXRail continues monitoring while minimized or locked, keeping you protected at all times.

🧭**Open Mapping Data**

Powered by OpenStreetMap and OpenRailwayMap for global-track accuracy.

👥 **Community Reporting** (Coming soon) 

Users can report missing or unsafe crossings to strengthen overall safety data.

📰 **Crash News & Safety Tips Videos**

A curated feed of railroad incident news and educational safety tips.

🧰 Technology Stack

RXRail is built using a modern, robust, and fully open-source foundation.


| Component         | Technology                                        |
| ----------------- | ------------------------------------------------- |
| **Frontend**      | Flutter (Dart)                                    |
| **Backend**       | Firebase or Supabase                              |
| **Mapping**       | OpenStreetMap, OpenRailwayMap, Overpass API       |
| **Routing / GPS** | OSRM Engine, geolocator                           |
| **Data Feeds**    | FRA, NHTSA, curated news & YouTube safety sources |
| **Hosting**       | GitHub Pages / rxrail.org                         |


📲 ****Download the App****

For now, clone and run locally:
#  
    git clone https://github.com/metviz/rxrailnew.git
  
    cd rxrailnew
  
    flutter pub get
  
    flutter run


📘 ****Documentation****

# ****RXRail Architecture Overview****

                +-----------------------+
                |     OpenStreetMap     |
                +-----------+-----------+
                            |
                            | Overpass API
                            |
                +-----------v-----------+
                |   Data Processing     |
                |  (Crossing Parsing)   |
                +-----------+-----------+
                            |
                            | GPS Location Stream
                            |
                +-----------v-----------+
                |  IntelAlert Engine    |
                | (Proximity Detection) |
                +-----------+-----------+
                            |
                            |
                +-----------v-----------+
                |   Mobile UI (Flutter) |
                +-----------------------+

Data Pipeline

IntelAlert Logic

Safety Disclaimer

User Flow & Screenshots (coming soon)

⚖️ ****Disclaimer****

RXRail uses publicly available, community-sourced data.
While we strive for accuracy, some data may be incomplete or outdated.
RXRail is intended as a **supplemental safety tool**, not a replacement for personal awareness, official signage, or emergency instructions.

In emergencies, always contact the ****railroad’s posted emergency number or local authorities****.

🤝 ****Contributing****

RXRail is fully open-source and welcomes contributions.
To get involved:
Fork the repository
Create a branch
Make improvements
Submit a pull request

🧡 ****Acknowledgments****

Thank you to:
OpenStreetMap & OpenRailwayMap contributors
FRA & NHTSA for public safety data
The open-source community
The Congressional App Challenge for inspiration

🌐 **Links**

🌎 **Website**: https://rxrail.org

🐙 **GitHub**: https://github.com/metviz/rxrailnew

---

> Parts of the codebase in this repository were developed with the assistance of [Claude Code](https://claude.ai/code) by Anthropic.
