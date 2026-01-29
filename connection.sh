#!/bin/bash

STATS_URL="http://localhost:8080/stat"
CHECK_INTERVAL=1
STREAM_DETECTED=false

echo "Monitoring Nginx RTMP stats..."

while true; do
    STREAM_NAME=$(curl -s $STATS_URL | xmllint --xpath "string(//rtmp/server/application/live/stream/name)" - 2>/dev/null)


    if [ -n "$STREAM_NAME" ]; then
        if [ "$STREAM_DETECTED" = false ]; then
            echo "Stream detected: $STREAM_NAME"
            STREAM_DETECTED=true

            INPUT_URL="rtmp://localhost:1935/live/$STREAM_NAME"
            mkdir /hls/stream_0 /hls/stream_1 /hls/stream_2 /hls/stream_3

            HAS_AUDIO=$(ffprobe -v error -select_streams a -show_entries stream=codec_type -of csv=p=0 "$INPUT_URL")

            echo "Detecting audio..."

            if [ -z "$HAS_AUDIO" ]; then
                echo "No audio detected. Using silent fallback."
                # Filter without [0:a]
                AUDIO_FILTER="anullsrc=channel_layout=stereo:sample_rate=44100[audio_out]"
                AUDIO_INPUT="-f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100"
            else
                echo "Audio detected. Mixing with fallback."
                # Filter mixing RTMP audio [0:a] with silence [1:a] just in case of drops
                AUDIO_FILTER="[0:a][1:a]amix=inputs=2:duration=first:dropout_transition=0[audio_out]"
                AUDIO_INPUT="-f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100"
            fi

            /usr/local/bin/ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
                -i "$INPUT_URL" \
                $AUDIO_INPUT \
                -filter_complex \
                "[0:v]split=2[4kout][4k60]; \
                [4k60]fps=30,split=3[v4k_pre][v4k_pre1][v4k_pre2]; \
                [v4k_pre]scale_cuda=w=2560:h=1440[2kout]; \
                [v4k_pre1]scale_cuda=w=1920:h=1080[1kout]; \
                [v4k_pre2]scale_cuda=w=1280:h=720[hdout]; \
                $AUDIO_FILTER" \
                -map "[4kout]" -c:v:0 h264_nvenc -preset p4 -b:v:0 12M -maxrate:v:0 12M -bufsize:v:0 24M \
                -map "[2kout]" -c:v:1 h264_nvenc -preset p4 -b:v:1 8M  -maxrate:v:1 8M  -bufsize:v:1 16M \
                -map "[1kout]" -c:v:2 h264_nvenc -preset p4 -b:v:2 5M  -maxrate:v:2 5M  -bufsize:v:2 10M \
                -map "[hdout]" -c:v:3 h264_nvenc -preset p4 -b:v:3 3M  -maxrate:v:3 3M  -bufsize:v:3 6M \
                -map "[audio_out]" -c:a:0 aac -b:a:0 128k -ar 44100 \
                -g 60 -keyint_min 60 -sc_threshold:v 0 \
                -f hls \
                -hls_time 4 \
                -hls_playlist_type event \
                -hls_flags delete_segments \
                -master_pl_name /hls/$STREAM_NAME.m3u8 \
                -var_stream_map "v:0,a:0 v:1,a:0 v:2,a:0 v:3,a:0" \
                -hls_segment_filename "stream_%v/data%03d.ts" "stream_%v/index.m3u8"

        fi
    else
        if [ "$STREAM_DETECTED" = true ]; then
            echo "Stream stopped."
            STREAM_DETECTED=false
        fi
    fi

    sleep "$CHECK_INTERVAL"
done

