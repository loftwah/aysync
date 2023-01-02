# Set up Amazon Music client
client = Amazon::Music.new(
    email: ENV['AMAZON_EMAIL'],
    password: ENV['AMAZON_PASSWORD']
  )
  
  # Get playlist from Amazon Music
  playlist = client.playlist(id: ENV['AMAZON_PLAYLIST_ID'])
  
  # Get track information from playlist
  tracks = playlist['tracks'].map do |track|
    {
      artist: track['artist']['name'],
      title: track['title'],
    }
  end
  
  # Set up YouTube client
  youtube = Google::Apis::YoutubeV3::YouTubeService.new
  youtube.key = ENV['YOUTUBE_API_KEY']
  
  # Create a new playlist on YouTube
  playlist_snippet = {
    title: playlist['name'],
    description: playlist['description'],
    tags: ['amazon', 'music', 'sync'],
    default_language: 'en'
  }
  playlist_status = {
    privacy_status: 'private'
  }
  
  playlist = youtube.insert_playlist('snippet,status',
                                     Google::Apis::YoutubeV3::Playlist.new(
                                       snippet: playlist_snippet,
                                       status: playlist_status
                                     ))
  
  # Add tracks to YouTube playlist
  tracks.each do |track|
    # Search for video on YouTube
    search_response = youtube.list_searches('id,snippet', type: 'video', q: "#{track[:artist]} #{track[:title]}", max_results: 1)
  
    # Get video ID from search results
    video_id = search_response.items.first.id.video_id
  
    # Add video to playlist
    youtube.insert_playlist_item('snippet',
                                 Google::Apis::YoutubeV3::PlaylistItem.new(
                                   snippet: {
                                     playlist_id: playlist.id,
                                     resource_id: {
                                       kind: 'youtube#video',
                                       video_id: video_id
                                     }
                                   }
                                 ))
  end
  
  puts 'Playlist synced!'  