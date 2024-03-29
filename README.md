# PayNow Plugin for Gmod

The official PayNow addon for Gmod servers enables seamless integration with PayNow gameservers, facilitating in-game transactions and more. This guide will help you set up the PayNow plugin on your server.

## Prerequisites

Ensure you have administrative access to your Gmod server and the ability to modify its configuration.

## Installation

Copy all files from this repository to a directory named `garrysmod/addons/paynow`.  

The PayNow plugin configuration is automatically saved into the `garrysmod/data/paynow` directory.

## Configuration

After the plugin is automatically installed and configured for the first time, you may want to customize its settings, such as the server connection token and the command fetch interval.

### Setting Your Token

To connect your server with the PayNow gameserver, set your unique PayNow token using the following server console command:

```plaintext
paynow.token <token>
```

Replace `<token>` with your actual PayNow token.

### Adjusting Fetch Interval

The default fetch interval is recommended for most servers, but you can adjust it to meet your specific needs:

```plaintext
paynow.interval_seconds <seconds>
```

Replace `<seconds>` with the desired interval in seconds. It's recommended to keep the default setting unless you have a specific reason to change it.

## Support

For support, questions, or more information, join our Discord community:

- [Discord](https://discord.gg/paynow)

## Contributing

Contributions are welcome! If you'd like to improve the PayNow plugin or suggest new features, please fork the repository, make your changes, and submit a pull request.
