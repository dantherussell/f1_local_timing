# F1 Local Timing

A Rails application for viewing Formula 1 race weekend schedules in your local timezone.

## Features

- View race weekend schedules with automatic timezone conversion
- Support for multiple racing series (F1, F2, F3, etc.)
- Light and dark theme toggle
- Print-friendly view for race weekends
- Admin interface for managing seasons, weekends, and events

## Tech Stack

- Ruby 3.3.5
- Rails 8.0
- PostgreSQL
- Hotwire (Turbo + Stimulus)
- RSpec for testing

## Setup

### Prerequisites

- Ruby 3.3.5
- PostgreSQL

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/f1_local_timing.git
cd f1_local_timing

# Install dependencies
bundle install

# Set up the database
bin/rails db:create db:migrate

# Start the server
bin/rails server
```

Visit `http://localhost:3000`

## Testing

```bash
bundle exec rspec
```

## Linting

```bash
bin/rubocop
```

## Environment Variables

For production, set the following:

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | PostgreSQL connection string |
| `ADMIN_USERNAME` | HTTP Basic auth username for admin actions |
| `ADMIN_PASSWORD` | HTTP Basic auth password for admin actions |
| `RAILS_MASTER_KEY` | Rails credentials master key |

## Heroku Deployment

```bash
# Create a new Heroku app
heroku create your-app-name

# Add PostgreSQL
heroku addons:create heroku-postgresql:essential-0

# Set environment variables
heroku config:set ADMIN_USERNAME=your_username
heroku config:set ADMIN_PASSWORD=your_password
heroku config:set RAILS_MASTER_KEY=$(cat config/master.key)

# Deploy
git push heroku main
```

Alternatively, connect GitHub for automatic deployments:
1. In Heroku Dashboard, go to Deploy tab
2. Connect to GitHub repository
3. Enable automatic deploys from `main` branch
4. Check "Wait for CI to pass before deploy"

## License

MIT
